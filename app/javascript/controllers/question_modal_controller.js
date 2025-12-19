import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "closeButton", "formContainer"]
  static values = { 
    questionId: Number,
    profileDomainId: Number,
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
    if (!this.hasFormContainerTarget || !this.questionIdValue || !this.profileDomainIdValue) {
      return
    }

    // Route: GET /admin/profile_domains/:id/questions/:question_id/edit_form
    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/edit_form`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    try {
      this.formContainerTarget.innerHTML = '<div class="flex justify-center items-center py-12"><span class="loading loading-spinner loading-lg"></span></div>'
      
      const response = await fetch(url, {
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.formContainerTarget.innerHTML = html
        
        // Re-initialize Stimulus controllers in the loaded content
        this.element.querySelectorAll('[data-controller]').forEach((el) => {
          const controllerName = el.dataset.controller
          // Turbo/Stimulus will handle this automatically, but we can trigger connect manually if needed
        })
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

