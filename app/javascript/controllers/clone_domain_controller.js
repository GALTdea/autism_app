import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    name: String,
    domainId: String
  }

  clone(event) {
    event.preventDefault()
    event.stopPropagation()

    console.log('Clone domain controller triggered', {
      url: this.urlValue,
      name: this.nameValue,
      domainId: this.domainIdValue
    })

    if (!confirm(`Clone '${this.nameValue}' as a standalone domain?`)) {
      return false
    }

    // Create a form outside the main form
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.urlValue
    form.style.display = 'none'
    
    // Set Turbo attributes
    form.setAttribute('data-turbo', 'true')
    form.setAttribute('data-turbo-frame', '_top')

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add domain_id
    const domainInput = document.createElement('input')
    domainInput.type = 'hidden'
    domainInput.name = 'domain_id'
    domainInput.value = this.domainIdValue
    form.appendChild(domainInput)

    // Append to body and submit
    document.body.appendChild(form)
    form.requestSubmit()
    
    // Clean up after a short delay
    setTimeout(() => {
      if (form.parentNode) {
        form.parentNode.removeChild(form)
      }
    }, 1000)

    return false
  }
}
