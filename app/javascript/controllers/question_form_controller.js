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
    responseType: String,
    domainId: Number,
    questionId: Number
  }

  static outlets = ["modal"]

  connect() {
    console.log("Question Form controller connected")
    // Only initialize form-specific features if the form targets exist
    if (this.hasResponseTypeSelectTarget) {
      this.updateOptionsVisibility()
      this.updateCharacterCount()
      this.setupOptionsInstructions()
    }
  }

  responseTypeValueChanged() {
    if (this.hasResponseTypeSelectTarget) {
      this.updateOptionsVisibility()
      this.updateOptionsInstructions()
      this.validateOptions()
    }
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
          <input type="hidden"
                 name="question[question_options_attributes][${index}][position]"
                 value="${currentPosition}">
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
      // Update the hidden position field
      const positionInput = row.querySelector('input[type="hidden"][name*="[position]"]')
      if (positionInput) {
        positionInput.value = index
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
    // Only validate if we have the necessary targets (i.e., form is loaded)
    if (!this.hasResponseTypeSelectTarget) {
      return true
    }

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

    // Close modal if it exists
    const modal = document.querySelector('[data-question-modal-target="modal"]')
    if (modal) {
      const modalController = this.application.getControllerForElementAndIdentifier(modal, 'question-modal')
      if (modalController) {
        modalController.close()
      }
    }

    if (window.history.length > 1) {
      window.history.back()
    } else {
      // Fallback: navigate to manage questions page
      const profileDomainId = window.location.pathname.match(/\/admin\/profile_domains\/(\d+)/)?.[1]
      const assessmentDomainId = window.location.pathname.match(/\/admin\/assessment_domains\/(\d+)/)?.[1]

      if (profileDomainId) {
        window.location.href = `/admin/profile_domains/${profileDomainId}/manage_questions`
      } else if (assessmentDomainId) {
        window.location.href = `/admin/assessment_domains/${assessmentDomainId}/manage_questions`
      }
    }
  }

  showBlankForm(event) {
    event.preventDefault()
    event.stopPropagation()

    const domainId = event.currentTarget.dataset.questionFormDomainIdParam ||
      event.currentTarget.getAttribute('data-question-form-domain-id-param') ||
      this.domainIdValue

    if (!domainId) {
      console.error("Domain ID is required. Element:", event.currentTarget)
      return
    }

    // Determine if this is a profile_domain or assessment_domain
    const path = window.location.pathname
    const isAssessmentDomain = path.includes('/assessment_domains/')

    // Find existing modal in the page - look for the controller element
    let modalControllerElement = document.querySelector('[data-controller*="question-modal"]')
    let modal = null
    if (modalControllerElement) {
      // Find the modal target within the controller element
      modal = modalControllerElement.querySelector('[data-question-modal-target="modal"]')
    }
    if (!modal) {
      // Fallback: try direct selector
      modal = document.querySelector('[data-question-modal-target="modal"]')
    }

    if (!modal) {
      console.error("Could not find question modal in page")
      return
    }

    // Get the controller element (parent of modal target)
    const controllerElement = modal.closest('[data-controller*="question-modal"]') || modal.parentElement

    // Get or wait for the modal controller
    let modalController = this.application.getControllerForElementAndIdentifier(controllerElement, 'question-modal')

    // If controller not found, wait a bit for Stimulus to connect it
    if (!modalController) {
      setTimeout(() => {
        modalController = this.application.getControllerForElementAndIdentifier(controllerElement, 'question-modal')
        if (modalController) {
          this.openModalWithForm(modalController, isAssessmentDomain, domainId, null)
        } else {
          // Fallback: manually open modal and load form
          this.manuallyOpenModal(modal, isAssessmentDomain, domainId, null)
        }
      }, 100)
    } else {
      this.openModalWithForm(modalController, isAssessmentDomain, domainId, null)
    }
  }

  openModalWithForm(modalController, isAssessmentDomain, domainId, questionId) {
    modalController.assessmentDomainIdValue = isAssessmentDomain ? parseInt(domainId) : null
    modalController.profileDomainIdValue = isAssessmentDomain ? null : parseInt(domainId)
    modalController.questionIdValue = questionId ? parseInt(questionId) : null
    modalController.open()
  }

  manuallyOpenModal(modal, isAssessmentDomain, domainId, questionId) {
    modal.classList.remove('hidden')
    modal.classList.add('modal-open')
    document.body.style.overflow = 'hidden'

    const formContainer = modal.querySelector('[data-question-modal-target="formContainer"]')
    if (formContainer) {
      this.loadFormIntoModal(modal, isAssessmentDomain, domainId, questionId)
    }
  }

  loadFormIntoModal(modal, isAssessmentDomain, domainId, questionId) {
    const formContainer = modal.querySelector('[data-question-modal-target="formContainer"]')
    if (!formContainer) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    const url = questionId
      ? `/admin/${isAssessmentDomain ? 'assessment_domains' : 'profile_domains'}/${domainId}/questions/${questionId}/edit`
      : `/admin/${isAssessmentDomain ? 'assessment_domains' : 'profile_domains'}/${domainId}/questions/new`

    formContainer.innerHTML = '<div class="flex justify-center items-center py-12"><span class="loading loading-spinner loading-lg"></span></div>'

    fetch(url, {
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/html"
      }
    })
      .then(response => response.text())
      .then(html => {
        formContainer.innerHTML = html
      })
      .catch(error => {
        console.error("Error loading form:", error)
        formContainer.innerHTML = `
        <div class="alert alert-error">
          <span>Error loading question form. Please check your connection.</span>
        </div>
      `
      })
  }

  showEditForm(event) {
    event.preventDefault()
    event.stopPropagation()

    const questionId = event.currentTarget.dataset.questionFormQuestionIdParam ||
      event.currentTarget.getAttribute('data-question-form-question-id-param') ||
      this.questionIdValue

    if (!questionId) {
      console.error("Question ID is required")
      return
    }

    // Determine if this is a profile_domain or assessment_domain
    const path = window.location.pathname
    const isAssessmentDomain = path.includes('/assessment_domains/')

    // Extract domain ID from path
    const domainIdMatch = path.match(/\/(\d+)\//)
    const domainId = domainIdMatch ? domainIdMatch[1] : null

    if (!domainId) {
      console.error("Could not extract domain ID from path:", path)
      return
    }

    // Find existing modal in the page - look for the controller element
    let modalControllerElement = document.querySelector('[data-controller*="question-modal"]')
    let modal = null
    if (modalControllerElement) {
      // Find the modal target within the controller element
      modal = modalControllerElement.querySelector('[data-question-modal-target="modal"]')
    }
    if (!modal) {
      // Fallback: try direct selector
      modal = document.querySelector('[data-question-modal-target="modal"]')
    }

    if (!modal) {
      console.error("Could not find question modal in page")
      return
    }

    // Get the controller element (parent of modal target)
    const controllerElement = modal.closest('[data-controller*="question-modal"]') || modal.parentElement

    // Get or wait for the modal controller
    let modalController = this.application.getControllerForElementAndIdentifier(controllerElement, 'question-modal')

    if (!modalController) {
      setTimeout(() => {
        modalController = this.application.getControllerForElementAndIdentifier(controllerElement, 'question-modal')
        if (modalController) {
          this.openModalWithForm(modalController, isAssessmentDomain, domainId, questionId)
        } else {
          this.manuallyOpenModal(modal, isAssessmentDomain, domainId, questionId)
        }
      }, 100)
    } else {
      this.openModalWithForm(modalController, isAssessmentDomain, domainId, questionId)
    }
  }

  createModal() {
    // Check if modal already exists in the page
    let modal = document.querySelector('[data-question-modal-target="modal"]')
    if (modal) {
      return modal
    }

    // Use the modal from the page if it exists
    const pageModal = document.querySelector('[data-controller*="question-modal"]')
    if (pageModal) {
      return pageModal
    }

    // Create new modal structure
    modal = document.createElement('div')
    modal.setAttribute('data-controller', 'question-modal')
    modal.setAttribute('data-question-modal-target', 'modal')
    modal.className = 'modal hidden'

    modal.innerHTML = `
      <div data-question-modal-target="backdrop" 
           class="modal-backdrop"
           data-action="click->question-modal#handleBackdropClick"></div>
      <div class="modal-box max-w-4xl max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
          <h3 class="font-bold text-2xl">Question</h3>
          <button type="button"
                  class="btn btn-sm btn-circle btn-ghost"
                  data-question-modal-target="closeButton"
                  data-action="click->question-modal#close">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        <div data-question-modal-target="formContainer" class="mt-4">
          <!-- Form will be loaded here via AJAX -->
        </div>
      </div>
    `

    // Append to body and let Stimulus auto-connect
    document.body.appendChild(modal)

    // Give Stimulus a moment to connect the controller
    setTimeout(() => {
      // Controller should be connected by now
    }, 10)

    return modal
  }
}



