import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "responseTypeSelect",
    "optionsSection",
    "optionsList",
    "addOptionButton",
    "optionsInfo",
    "optionsInstructions",
    "optionsError",
    "textInput",
    "textCount",
    "textError",
    "codeInput",
    "codeError",
    "submitButton"
  ]

  static values = {
    responseType: String
  }

  connect() {
    console.log("Question Form controller connected")
    this.updateOptionsVisibility()
    this.updateCharacterCount()
    this.setupOptionsInstructions()
  }

  responseTypeValueChanged() {
    this.updateOptionsVisibility()
    this.updateOptionsInstructions()
    this.validateOptions()
  }

  handleResponseTypeChange(event) {
    this.responseTypeValue = event.target.value
    this.clearOptionsValidation()
  }

  updateOptionsVisibility() {
    if (this.hasResponseTypeSelectTarget) {
      const responseType = this.responseTypeSelectTarget.value
      
      if (responseType === 'text') {
        this.optionsSectionTarget?.classList.add('hidden')
        // Clear options requirement for text type
        this.clearOptionsValidation()
      } else {
        this.optionsSectionTarget?.classList.remove('hidden')
        // Validate options are present for scale/multi_choice
        this.validateOptions()
      }
    }
  }

  updateOptionsInstructions() {
    if (!this.hasOptionsInstructionsTarget) return

    const responseType = this.responseTypeSelectTarget?.value || 'scale'
    
    if (responseType === 'scale') {
      this.optionsInstructionsTarget.innerHTML = `
        For <strong>Scale</strong> questions, order options from <strong>highest to lowest</strong> value.
        Options should represent a rating scale (e.g., Always = 4, Often = 3, Sometimes = 2, Rarely = 1, Never = 0).
      `
    } else if (responseType === 'multi_choice') {
      this.optionsInstructionsTarget.innerHTML = `
        For <strong>Multi-choice</strong> questions, add all available choices.
        Values don't need to be sequential but should represent the option's significance.
      `
    }
  }

  setupOptionsInstructions() {
    this.updateOptionsInstructions()
  }

  addOption(event) {
    event.preventDefault()
    
    const optionIndex = Date.now() // Use timestamp as unique index
    const optionRow = this.createOptionRow(optionIndex)
    
    if (this.hasOptionsListTarget) {
      // Remove empty state message if present
      const emptyState = this.optionsListTarget.querySelector('.text-center')
      if (emptyState) {
        emptyState.remove()
      }
      
      this.optionsListTarget.insertAdjacentHTML('beforeend', optionRow)
    }
    
    this.validateOptions()
  }

  createOptionRow(index) {
    const currentPosition = this.optionsListTarget?.querySelectorAll('[data-question-form-target="optionRow"]').length || 0
    
    return `
      <div class="flex items-center gap-3 p-3 bg-base-100 rounded-box border border-base-300" data-question-form-target="optionRow">
        <div class="flex items-center gap-2 flex-1">
          <span class="badge badge-neutral badge-lg min-w-[3rem] justify-center">${currentPosition + 1}</span>
          <input type="text" 
                 placeholder="Option label (e.g., Always, Often, Sometimes)"
                 class="input input-bordered flex-1"
                 data-question-form-target="optionLabel"
                 name="question[question_options_attributes][${index}][label]"
                 required>
          <input type="number" 
                 placeholder="Value"
                 class="input input-bordered w-24"
                 data-question-form-target="optionValue"
                 name="question[question_options_attributes][${index}][value]"
                 value="${currentPosition}"
                 min="0"
                 step="1"
                 required>
        </div>
        <button type="button" 
                class="btn btn-sm btn-error btn-ghost"
                data-action="click->question-form#removeOption"
                data-option-index="${index}">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `
  }

  removeOption(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const optionRow = button.closest('[data-question-form-target="optionRow"]')
    
    if (optionRow) {
      optionRow.remove()
      this.updateOptionPositions()
      this.validateOptions()
    }
  }

  updateOptionPositions() {
    const rows = this.optionsListTarget?.querySelectorAll('[data-question-form-target="optionRow"]') || []
    rows.forEach((row, index) => {
      const badge = row.querySelector('.badge')
      if (badge) {
        badge.textContent = index + 1
      }
    })
  }

  validateText(event) {
    const text = event.target.value
    const minLength = 10
    const maxLength = 500
    
    if (this.hasTextErrorTarget) {
      if (text.length < minLength && text.length > 0) {
        this.textErrorTarget.textContent = `Question text must be at least ${minLength} characters long.`
        this.textErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
      } else if (text.length > maxLength) {
        this.textErrorTarget.textContent = `Question text cannot exceed ${maxLength} characters.`
        this.textErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
      } else {
        this.textErrorTarget.classList.add('hidden')
        event.target.classList.remove('input-error')
      }
    }
    
    this.updateCharacterCount()
  }

  updateCharacterCount() {
    if (this.hasTextInputTarget && this.hasTextCountTarget) {
      const text = this.textInputTarget.value
      const maxLength = 500
      const remaining = maxLength - text.length
      
      this.textCountTarget.textContent = `${text.length} / ${maxLength} characters`
      
      if (remaining < 50) {
        this.textCountTarget.classList.add('text-warning')
        this.textCountTarget.classList.remove('text-base-content/60')
      } else {
        this.textCountTarget.classList.remove('text-warning')
        this.textCountTarget.classList.add('text-base-content/60')
      }
    }
  }

  validateCode(event) {
    const code = event.target.value
    const codePattern = /^[A-Z0-9_]+$/
    
    if (this.hasCodeErrorTarget) {
      if (code && !codePattern.test(code)) {
        this.codeErrorTarget.textContent = "Code must contain only uppercase letters, numbers, and underscores."
        this.codeErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
      } else {
        this.codeErrorTarget.classList.add('hidden')
        event.target.classList.remove('input-error')
      }
    }
  }

  validateOptions() {
    const responseType = this.responseTypeSelectTarget?.value
    
    if (responseType === 'text') {
      this.clearOptionsValidation()
      return true
    }
    
    if (!this.hasOptionsListTarget) {
      return false
    }
    
    const optionRows = this.optionsListTarget.querySelectorAll('[data-question-form-target="optionRow"]')
    const hasOptions = optionRows.length > 0
    
    if (!hasOptions && (responseType === 'scale' || responseType === 'multi_choice')) {
      if (this.hasOptionsErrorTarget) {
        this.optionsErrorTarget.classList.remove('hidden')
      }
      return false
    } else {
      this.clearOptionsValidation()
      return true
    }
  }

  clearOptionsValidation() {
    if (this.hasOptionsErrorTarget) {
      this.optionsErrorTarget.classList.add('hidden')
    }
  }

  validateBeforeSubmit(event) {
    // Validate all required fields
    const responseType = this.responseTypeSelectTarget?.value
    const text = this.textInputTarget?.value || ''
    const code = this.codeInputTarget?.value || ''
    
    let isValid = true
    
    // Validate text
    if (text.length < 10) {
      this.validateText({ target: this.textInputTarget })
      isValid = false
    }
    
    // Validate code format if provided
    if (code && !/^[A-Z0-9_]+$/.test(code)) {
      this.validateCode({ target: this.codeInputTarget })
      isValid = false
    }
    
    // Validate options for scale/multi_choice
    if (!this.validateOptions() && responseType !== 'text') {
      isValid = false
    }
    
    if (!isValid) {
      event.preventDefault()
      
      // Scroll to first error
      const firstError = this.element.querySelector('.input-error, .alert-error:not(.hidden)')
      if (firstError) {
        firstError.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    }
  }

  handleSubmit(event) {
    // Handle Turbo Stream response
    if (event.detail.success) {
      console.log("Question saved successfully")
      // Could emit custom event or trigger other actions here
    }
  }

  cancelForm(event) {
    event.preventDefault()
    
    if (window.history.length > 1) {
      window.history.back()
    } else {
      // Fallback: navigate to manage questions page
      const domainId = window.location.pathname.match(/\/admin\/profile_domains\/(\d+)/)?.[1]
      if (domainId) {
        window.location.href = `/admin/profile_domains/${domainId}/manage_questions`
      }
    }
  }
}

