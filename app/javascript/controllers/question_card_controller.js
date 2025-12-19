import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "collapseButton",
    "collapseContent",
    "questionText",
    "questionCode",
    "questionType",
    "editButton",
    "deleteButton",
    "inlineEditForm",
    "viewMode",
    "saveButton",
    "cancelButton"
  ]

  static values = {
    questionId: Number,
    profileDomainId: Number,
    isCollapsed: Boolean
  }

  connect() {
    // Initialize collapsed state
    this.isCollapsedValue = true
    this.updateCollapseState()
  }

  toggleCollapse(event) {
    event.preventDefault()
    this.isCollapsedValue = !this.isCollapsedValue
    this.updateCollapseState()
  }

  updateCollapseState() {
    if (this.hasCollapseContentTarget) {
      if (this.isCollapsedValue) {
        this.collapseContentTarget.classList.add("hidden")
        this.collapseButtonTarget?.querySelector("svg")?.classList.remove("rotate-180")
      } else {
        this.collapseContentTarget.classList.remove("hidden")
        this.collapseButtonTarget?.querySelector("svg")?.classList.add("rotate-180")
      }
    }
  }

  enableInlineEdit(event) {
    event.preventDefault()
    
    if (this.hasViewModeTarget) {
      this.viewModeTarget.classList.add("hidden")
    }
    
    if (this.hasInlineEditFormTarget) {
      this.inlineEditFormTarget.classList.remove("hidden")
      // Focus on question text input
      const textInput = this.inlineEditFormTarget.querySelector('textarea[name*="[text]"]')
      if (textInput) {
        textInput.focus()
        textInput.select()
      }
    }
  }

  cancelInlineEdit(event) {
    event.preventDefault()
    
    if (this.hasViewModeTarget) {
      this.viewModeTarget.classList.remove("hidden")
    }
    
    if (this.hasInlineEditFormTarget) {
      this.inlineEditFormTarget.classList.add("hidden")
      // Reset form to original values
      this.resetForm()
    }
  }

  resetForm() {
    // Form will be reset by browser on cancel, but we can add custom logic here if needed
  }

  async saveInlineEdit(event) {
    // This is called after Turbo submit, so we just need to handle the response
    if (event.detail && event.detail.success !== false) {
      // Success - form will be replaced by Turbo Stream
      // Reset to view mode after a short delay
      setTimeout(() => {
        if (this.hasViewModeTarget) {
          this.viewModeTarget.classList.remove("hidden")
        }
        if (this.hasInlineEditFormTarget) {
          this.inlineEditFormTarget.classList.add("hidden")
        }
      }, 100)
    } else {
      // Error - show error message
      this.showError("Failed to save question. Please check the form for errors.")
    }
  }

  showError(message) {
    // Create or update error message
    let errorDiv = this.element.querySelector('[data-question-card-target="errorMessage"]')
    if (!errorDiv) {
      errorDiv = document.createElement("div")
      errorDiv.setAttribute("data-question-card-target", "errorMessage")
      errorDiv.className = "alert alert-error mt-2"
      this.element.insertBefore(errorDiv, this.element.firstChild)
    }
    
    errorDiv.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <span>${message}</span>
    `
    
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  openEditModal(event) {
    event.preventDefault()
    
    // Dispatch custom event to open modal
    const modalEvent = new CustomEvent("question-card:open-edit-modal", {
      detail: { questionId: this.questionIdValue, profileDomainId: this.profileDomainIdValue },
      bubbles: true
    })
    this.element.dispatchEvent(modalEvent)
  }
}

