import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "currentStep",
    "totalSteps",
    "progressBar",
    "stepIndicator",
    "backButton",
    "nextButton",
    "saveButton"
  ]

  static values = {
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 4 },
    profileDomainId: { type: Number, default: 0 }
  }

  connect() {
    console.log("Domain Builder controller connected")
    this.updateProgress()
    this.updateStepIndicators()
    this.updateNavigationButtons()
    this.loadState()
  }

  currentStepValueChanged() {
    this.updateProgress()
    this.updateStepIndicators()
    this.updateNavigationButtons()
    this.saveState()
  }

  goToStep(step) {
    if (step >= 1 && step <= this.totalStepsValue) {
      this.currentStepValue = step
      this.saveState()
    }
  }

  goBack() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.navigateToStep(this.currentStepValue)
    }
  }

  goNext() {
    if (this.currentStepValue < this.totalStepsValue) {
      // Validate current step before proceeding
      if (this.validateCurrentStep()) {
        this.currentStepValue++
        this.navigateToStep(this.currentStepValue)
      }
    }
  }

  navigateToStep(step) {
    // Navigate based on step number
    const baseUrl = `/admin/profile_domains/${this.profileDomainIdValue}`
    
    let url
    switch(step) {
      case 1:
        url = `${baseUrl}/edit`
        break
      case 2:
        url = `${baseUrl}/manage_questions`
        break
      case 3:
        // Configure options (same as manage_questions but focused on options)
        url = `${baseUrl}/manage_questions`
        break
      case 4:
        url = `${baseUrl}/preview`
        break
      default:
        url = baseUrl
    }

    window.location.href = url
  }

  updateProgress() {
    if (this.hasProgressBarTarget) {
      const percentage = (this.currentStepValue / this.totalStepsValue) * 100
      this.progressBarTarget.style.width = `${percentage}%`
    }

    if (this.hasCurrentStepTarget) {
      this.currentStepTarget.textContent = this.currentStepValue
    }

    if (this.hasTotalStepsTarget) {
      this.totalStepsTarget.textContent = this.totalStepsValue
    }
  }

  updateStepIndicators() {
    if (!this.hasStepIndicatorTargets) return

    this.stepIndicatorTargets.forEach((indicator, index) => {
      const stepNumber = index + 1
      indicator.classList.remove("step-primary", "step-success")
      
      if (stepNumber < this.currentStepValue) {
        indicator.classList.add("step-success")
      } else if (stepNumber === this.currentStepValue) {
        indicator.classList.add("step-primary")
      }
    })
  }

  updateNavigationButtons() {
    if (this.hasBackButtonTarget) {
      this.backButtonTarget.disabled = this.currentStepValue === 1
      this.backButtonTarget.classList.toggle("btn-disabled", this.currentStepValue === 1)
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.currentStepValue === this.totalStepsValue
      this.nextButtonTarget.classList.toggle("btn-disabled", this.currentStepValue === this.totalStepsValue)
      
      // Change button text for last step
      if (this.currentStepValue === this.totalStepsValue) {
        this.nextButtonTarget.textContent = "Complete"
      } else {
        this.nextButtonTarget.textContent = "Next"
      }
    }

    if (this.hasSaveButtonTarget) {
      // Show save button on steps where it makes sense
      const showSave = this.currentStepValue === 1 || this.currentStepValue === 2
      this.saveButtonTarget.classList.toggle("hidden", !showSave)
    }
  }

  validateCurrentStep() {
    // Add validation logic for each step
    switch(this.currentStepValue) {
      case 1:
        // Validate basic info (key, label)
        return this.validateBasicInfo()
      case 2:
        // Validate questions exist
        return this.validateQuestions()
      case 3:
        // Validate options for scale/multi_choice questions
        return this.validateOptions()
      case 4:
        // Preview step, always valid
        return true
      default:
        return true
    }
  }

  validateBasicInfo() {
    // Check if key and label are filled
    const keyField = this.element.querySelector('input[name="profile_domain[key]"]')
    const labelField = this.element.querySelector('input[name="profile_domain[label]"]')
    
    if (keyField && !keyField.value.trim()) {
      this.showError("Domain key is required")
      keyField.focus()
      return false
    }
    
    if (labelField && !labelField.value.trim()) {
      this.showError("Domain label is required")
      labelField.focus()
      return false
    }
    
    return true
  }

  validateQuestions() {
    // Check if at least one question exists
    // This would typically be done server-side, but we can check for visual indicators
    const questionsList = this.element.querySelector('[data-domain-builder-target="questionsList"]')
    if (questionsList) {
      const questionCount = questionsList.querySelectorAll('[data-question-id]').length
      if (questionCount === 0) {
        this.showError("Please add at least one question before proceeding")
        return false
      }
    }
    return true
  }

  validateOptions() {
    // Check if scale/multi_choice questions have options
    const questionsWithoutOptions = this.element.querySelectorAll('[data-response-type="scale"], [data-response-type="multi_choice"]')
    let hasInvalid = false

    questionsWithoutOptions.forEach((questionElement) => {
      const optionsList = questionElement.querySelector('[data-question-options-manager-target="optionsList"]')
      const optionCount = optionsList ? optionsList.querySelectorAll('[data-option-id]').length : 0
      
      if (optionCount === 0) {
        hasInvalid = true
        questionElement.classList.add("border-error", "border-2")
      } else {
        questionElement.classList.remove("border-error", "border-2")
      }
    })

    if (hasInvalid) {
      this.showError("Scale and Multi-choice questions must have at least one option")
      return false
    }

    return true
  }

  saveState() {
    if (this.profileDomainIdValue > 0) {
      try {
        sessionStorage.setItem(`domain-builder-${this.profileDomainIdValue}`, JSON.stringify({
          currentStep: this.currentStepValue,
          timestamp: Date.now()
        }))
      } catch (e) {
        console.warn("Could not save domain builder state:", e)
      }
    }
  }

  loadState() {
    if (this.profileDomainIdValue > 0) {
      try {
        const saved = sessionStorage.getItem(`domain-builder-${this.profileDomainIdValue}`)
        if (saved) {
          const state = JSON.parse(saved)
          // Only restore if saved recently (within 1 hour)
          if (Date.now() - state.timestamp < 3600000) {
            this.currentStepValue = state.currentStep
          }
        }
      } catch (e) {
        console.warn("Could not load domain builder state:", e)
      }
    }
  }

  clearState() {
    if (this.profileDomainIdValue > 0) {
      try {
        sessionStorage.removeItem(`domain-builder-${this.profileDomainIdValue}`)
      } catch (e) {
        console.warn("Could not clear domain builder state:", e)
      }
    }
  }

  showError(message) {
    // Create or update error alert
    let alert = document.getElementById("domain-builder-error")
    if (!alert) {
      alert = document.createElement("div")
      alert.id = "domain-builder-error"
      alert.className = "alert alert-error fixed top-4 right-4 z-50 max-w-md shadow-lg"
      document.body.appendChild(alert)
    }

    alert.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <span>${message}</span>
      <button onclick="this.parentElement.remove()" class="btn btn-sm btn-circle btn-ghost">✕</button>
    `

    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (alert.parentNode) {
        alert.remove()
      }
    }, 5000)
  }
}

