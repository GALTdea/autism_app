import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    currentStep: Number,
    totalSteps: Number,
    assessmentId: Number
  }

  static targets = ["step", "progressBar", "backButton", "nextButton"]

  connect() {
    this.updateProgress()
    this.updateNavigationButtons()
  }

  updateProgress() {
    if (this.hasProgressBarTarget) {
      const percentage = (this.currentStepValue / this.totalStepsValue) * 100
      this.progressBarTarget.style.width = `${percentage}%`
    }
  }

  updateNavigationButtons() {
    // Update back button visibility
    if (this.hasBackButtonTarget) {
      if (this.currentStepValue === 1) {
        this.backButtonTarget.classList.add("hidden")
      } else {
        this.backButtonTarget.classList.remove("hidden")
      }
    }

    // Update next button text based on step
    if (this.hasNextButtonTarget) {
      if (this.currentStepValue === this.totalStepsValue) {
        this.nextButtonTarget.textContent = "Finish"
      } else {
        this.nextButtonTarget.textContent = "Next"
      }
    }
  }

  getStepUrl(stepNumber) {
    const assessmentId = this.assessmentIdValue
    const stepUrls = {
      1: `/admin/assessments/${assessmentId}`,
      2: `/admin/assessments/${assessmentId}/select_domains`,
      3: `/admin/assessments/${assessmentId}/order_domains`,
      4: `/admin/assessments/${assessmentId}/preview`
    }
    return stepUrls[stepNumber] || null
  }

  goToStep(stepNumber) {
    const url = this.getStepUrl(stepNumber)
    if (url) {
      Turbo.visit(url)
    }
  }

  goBack() {
    if (this.currentStepValue > 1) {
      this.goToStep(this.currentStepValue - 1)
    }
  }

  goNext() {
    if (this.currentStepValue < this.totalStepsValue) {
      this.goToStep(this.currentStepValue + 1)
    }
  }

  // Save wizard state to sessionStorage
  saveState(data) {
    const key = `assessment_builder_${this.assessmentIdValue}`
    const state = {
      currentStep: this.currentStepValue,
      assessmentId: this.assessmentIdValue,
      data: data || {}
    }
    sessionStorage.setItem(key, JSON.stringify(state))
  }

  // Load wizard state from sessionStorage
  loadState() {
    const key = `assessment_builder_${this.assessmentIdValue}`
    const saved = sessionStorage.getItem(key)
    return saved ? JSON.parse(saved) : null
  }

  // Clear wizard state
  clearState() {
    const key = `assessment_builder_${this.assessmentIdValue}`
    sessionStorage.removeItem(key)
  }
}

