import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["templatesModal", "templatesContainer", "copyModal", "copyContainer"]
  static values = { 
    profileDomainId: Number
  }

  async showTemplates(event) {
    event.preventDefault()
    
    if (this.hasTemplatesModalTarget) {
      this.templatesModalTarget.classList.remove("hidden")
      this.templatesModalTarget.classList.add("modal-open")
      document.body.style.overflow = "hidden"
      
      // Load templates partial
      await this.loadTemplates()
    }
  }

  hideTemplates(event) {
    if (event) event.preventDefault()
    
    if (this.hasTemplatesModalTarget) {
      this.templatesModalTarget.classList.add("hidden")
      this.templatesModalTarget.classList.remove("modal-open")
      document.body.style.overflow = ""
    }
  }

  async showCopyFromDomain(event) {
    event.preventDefault()
    
    if (this.hasCopyModalTarget) {
      this.copyModalTarget.classList.remove("hidden")
      this.copyModalTarget.classList.add("modal-open")
      document.body.style.overflow = "hidden"
      
      // Load copy form
      await this.loadCopyForm()
    }
  }

  hideCopyFromDomain(event) {
    if (event) event.preventDefault()
    
    if (this.hasCopyModalTarget) {
      this.copyModalTarget.classList.add("hidden")
      this.copyModalTarget.classList.remove("modal-open")
      document.body.style.overflow = ""
    }
  }

  handleTemplateSubmit(event) {
    // Close modal after successful template creation
    // The Turbo Stream response will handle updating the list
    setTimeout(() => {
      this.hideTemplates()
    }, 100)
  }

  async loadTemplates() {
    if (!this.hasTemplatesContainerTarget || !this.profileDomainIdValue) {
      return
    }

    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/templates`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    try {
      this.templatesContainerTarget.innerHTML = '<div class="flex justify-center items-center py-12"><span class="loading loading-spinner loading-lg"></span></div>'
      
      const response = await fetch(url, {
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.templatesContainerTarget.innerHTML = html
      } else {
        this.templatesContainerTarget.innerHTML = `
          <div class="alert alert-error">
            <span>Failed to load templates. Please try again.</span>
          </div>
        `
      }
    } catch (error) {
      console.error("Error loading templates:", error)
      this.templatesContainerTarget.innerHTML = `
        <div class="alert alert-error">
          <span>Error loading templates. Please check your connection.</span>
        </div>
      `
    }
  }

  async loadCopyForm() {
    if (!this.hasCopyContainerTarget || !this.profileDomainIdValue) {
      return
    }

    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/copy_from_domain_form`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    try {
      this.copyContainerTarget.innerHTML = '<div class="flex justify-center items-center py-12"><span class="loading loading-spinner loading-lg"></span></div>'
      
      const response = await fetch(url, {
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.copyContainerTarget.innerHTML = html
      } else {
        this.copyContainerTarget.innerHTML = `
          <div class="alert alert-error">
            <span>Failed to load domains. Please try again.</span>
          </div>
        `
      }
    } catch (error) {
      console.error("Error loading copy form:", error)
      this.copyContainerTarget.innerHTML = `
        <div class="alert alert-error">
          <span>Error loading domains. Please check your connection.</span>
        </div>
      `
    }
  }
}

