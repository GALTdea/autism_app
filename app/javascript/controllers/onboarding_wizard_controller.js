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
        // Store reference to element before async operation (event.currentTarget can become stale)
        const element = event.currentTarget
        const questionId = element.dataset.questionId
        const currentStep = element.dataset.currentStep
        const form = element.closest('form')

        if (!form || !element) return

        // Create form data with only the current question's data
        const formData = new FormData()
        formData.append('authenticity_token', form.querySelector('input[name="authenticity_token"]')?.value || '')
        formData.append('question_id', questionId)
        formData.append('current_step', currentStep)

        // Get the selected value for THIS question only
        if (element.type === 'radio') {
            formData.append('question_option_id', element.value)
        } else if (element.tagName === 'TEXTAREA') {
            formData.append('free_text', element.value)
        }

        // Save answer via fetch (AJAX)
        fetch(form.action, {
            method: 'PATCH',
            body: formData,
            headers: {
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            credentials: 'same-origin'
        }).then(response => {
            if (response.ok) {
                return response.json().then(data => {
                    // Show a subtle success indicator - use stored element reference
                    if (element && element.isConnected) {
                        this.showSaveIndicator(element)
                    }
                })
            } else {
                // Handle error response
                return response.json().then(data => {
                    console.error('Error saving answer:', data.error || 'Unknown error')
                    if (element && element.isConnected) {
                        this.showErrorIndicator(element)
                    }
                }).catch(() => {
                    console.error('Error saving answer: Server returned', response.status)
                    if (element && element.isConnected) {
                        this.showErrorIndicator(element)
                    }
                })
            }
        }).catch(error => {
            console.error('Error saving answer:', error)
            if (element && element.isConnected) {
                this.showErrorIndicator(element)
            }
        })
    }

    showSaveIndicator(element) {
        // Check if element still exists in DOM
        if (!element || !element.isConnected) {
            console.warn('Element no longer in DOM, cannot show save indicator')
            return
        }

        // Find the label element (for radio buttons) or use the element itself (for textarea)
        const container = element.closest('label') || element.parentElement

        if (!container) {
            console.warn('Could not find container for save indicator')
            return
        }

        // Add a subtle visual indicator that the answer was saved
        const indicator = document.createElement('span')
        indicator.textContent = '✓ Saved'
        indicator.className = 'text-green-600 text-sm ml-2'

        // Remove any existing indicators
        const existing = container.querySelector('.text-green-600, .text-red-600')
        if (existing) existing.remove()

        container.appendChild(indicator)

        // Remove after 2 seconds
        setTimeout(() => {
            if (indicator.parentElement) {
                indicator.remove()
            }
        }, 2000)
    }

    showErrorIndicator(element) {
        // Check if element still exists in DOM
        if (!element || !element.isConnected) {
            console.warn('Element no longer in DOM, cannot show error indicator')
            return
        }

        // Find the label element (for radio buttons) or use the element itself (for textarea)
        const container = element.closest('label') || element.parentElement

        if (!container) {
            console.warn('Could not find container for error indicator')
            return
        }

        // Add a subtle visual indicator that there was an error
        const indicator = document.createElement('span')
        indicator.textContent = '✗ Error'
        indicator.className = 'text-red-600 text-sm ml-2'

        // Remove any existing indicators
        const existing = container.querySelector('.text-green-600, .text-red-600')
        if (existing) existing.remove()

        container.appendChild(indicator)

        // Remove after 3 seconds
        setTimeout(() => {
            if (indicator.parentElement) {
                indicator.remove()
            }
        }, 3000)
    }
}

