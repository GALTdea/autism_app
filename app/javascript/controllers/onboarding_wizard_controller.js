import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    currentStep: Number,
    totalSteps: Number
  }

  connect() {
    console.log("Onboarding wizard controller connected")
  }

  saveAnswer(event) {
    const questionId = event.currentTarget.dataset.questionId
    const currentStep = event.currentTarget.dataset.currentStep
    const form = event.currentTarget.closest('form')
    
    if (!form) return

    const formData = new FormData(form)
    formData.append('question_id', questionId)
    formData.append('current_step', currentStep)

    // Get the selected value
    if (event.currentTarget.type === 'radio') {
      formData.set('question_option_id', event.currentTarget.value)
    } else if (event.currentTarget.tagName === 'TEXTAREA') {
      formData.set('free_text', event.currentTarget.value)
    }

    // Save answer via Turbo
    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(response => {
      if (response.ok) {
        // Show a subtle success indicator
        this.showSaveIndicator(event.currentTarget)
      }
    }).catch(error => {
      console.error('Error saving answer:', error)
    })
  }

  showSaveIndicator(element) {
    // Add a subtle visual indicator that the answer was saved
    const indicator = document.createElement('span')
    indicator.textContent = '✓ Saved'
    indicator.className = 'text-green-600 text-sm ml-2'
    
    // Remove any existing indicator
    const existing = element.parentElement.querySelector('.text-green-600')
    if (existing) existing.remove()
    
    element.parentElement.appendChild(indicator)
    
    // Remove after 2 seconds
    setTimeout(() => {
      indicator.remove()
    }, 2000)
  }
}

