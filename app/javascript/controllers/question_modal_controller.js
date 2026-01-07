import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "closeButton", "formContainer"]
  static values = {
    questionId: Number,
    profileDomainId: Number,
    assessmentDomainId: Number,
    isOpen: Boolean
  }

  connect() {
    // Listen for custom events to open modal
    document.addEventListener("question-card:open-edit-modal", this.handleOpenModal.bind(this))

    // Close on escape key
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("question-card:open-edit-modal", this.handleOpenModal.bind(this))
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleOpenModal(event) {
    const { questionId, profileDomainId } = event.detail
    this.questionIdValue = questionId
    this.profileDomainIdValue = profileDomainId
    this.open()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpenValue) {
      this.close()
    }
  }

  open() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.classList.add("modal-open")
      document.body.style.overflow = "hidden"
      this.isOpenValue = true

      // Update modal title
      const titleElement = this.modalTarget.querySelector('h3')
      if (titleElement) {
        titleElement.textContent = this.questionIdValue ? "Edit Question" : "Create Question"
      }

      // Load question form
      this.loadQuestionForm()
    }
  }

  close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.classList.remove("modal-open")
      document.body.style.overflow = ""
      this.isOpenValue = false

      // Clear form container
      if (this.hasFormContainerTarget) {
        this.formContainerTarget.innerHTML = ""
      }
    }
  }

  async loadQuestionForm() {
    if (!this.hasFormContainerTarget) {
      return
    }

    // Determine if we're creating or editing
    const isEditing = this.questionIdValue && this.questionIdValue > 0
    const isAssessmentDomain = this.assessmentDomainIdValue && this.assessmentDomainIdValue > 0

    let url
    if (isEditing) {
      if (isAssessmentDomain) {
        // For assessment_domains, we'll need to load the question and render the form
        // Since there's no edit_form route, we'll fetch the question and render inline
        url = null // We'll handle this differently
      } else {
        url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/edit_form`
      }
    } else {
      // For new questions, render the form inline
      url = null
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    try {
      this.formContainerTarget.innerHTML = '<div class="flex justify-center items-center py-12"><span class="loading loading-spinner loading-lg"></span></div>'

      if (url) {
        // Load form from server
        const response = await fetch(url, {
          headers: {
            "X-CSRF-Token": csrfToken,
            "Accept": "text/html"
          }
        })

        if (response.ok) {
          const html = await response.text()
          this.formContainerTarget.innerHTML = html
        } else {
          this.formContainerTarget.innerHTML = `
            <div class="alert alert-error">
              <span>Failed to load question form. Please try again.</span>
            </div>
          `
        }
      } else {
        // Render form inline for assessment_domains
        if (isAssessmentDomain) {
          this.renderAssessmentDomainForm()
        } else {
          // For profile_domains creating new, we can redirect or render inline
          this.formContainerTarget.innerHTML = `
            <div class="alert alert-info">
              <span>Please use the "Blank Question" button to create a new question.</span>
            </div>
          `
        }
      }
    } catch (error) {
      console.error("Error loading question form:", error)
      this.formContainerTarget.innerHTML = `
        <div class="alert alert-error">
          <span>Error loading question form. Please check your connection.</span>
        </div>
      `
    }
  }

  async renderAssessmentDomainForm() {
    const isEditing = this.questionIdValue && this.questionIdValue > 0
    const domainId = this.assessmentDomainIdValue

    if (!domainId) {
      this.formContainerTarget.innerHTML = `
        <div class="alert alert-error">
          <span>Domain ID is required.</span>
        </div>
      `
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    const url = isEditing
      ? `/admin/assessment_domains/${domainId}/questions/${this.questionIdValue}/edit`
      : `/admin/assessment_domains/${domainId}/questions/new`

    try {
      const response = await fetch(url, {
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.formContainerTarget.innerHTML = html
      } else {
        this.formContainerTarget.innerHTML = `
          <div class="alert alert-error">
            <span>Failed to load question form. Please try again.</span>
          </div>
        `
      }
    } catch (error) {
      console.error("Error loading question form:", error)
      this.formContainerTarget.innerHTML = `
        <div class="alert alert-error">
          <span>Error loading question form. Please check your connection.</span>
        </div>
      `
    }
  }

  async loadQuestionAndRenderForm() {
    // This would fetch question data and render the form
    // For now, show an error message
    this.formContainerTarget.innerHTML = `
      <div class="alert alert-error">
        <span>Failed to load question. Please refresh the page and try again.</span>
      </div>
    `
  }

  renderBlankForm() {
    // Render a basic form structure
    // The actual form will be loaded via the partial
    this.formContainerTarget.innerHTML = `
      <div class="alert alert-info">
        <span>Loading form...</span>
      </div>
    `
  }

  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleSubmitSuccess(event) {
    // Close modal after successful submit
    setTimeout(() => {
      this.close()
    }, 300)
  }
}

