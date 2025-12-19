import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "labelInput",
    "valueInput",
    "labelError",
    "valueError",
    "submitButton"
  ]

  static values = {
    responseType: String,
    questionId: Number,
    profileDomainId: Number,
    inline: Boolean,
    min: Number,
    max: Number,
    typicalMax: Number
  }

  connect() {
    console.log("Question Option Form controller connected")
    if (this.responseTypeValue === 'scale' && this.typicalMaxValue) {
      this.checkValueRange()
    }
  }

  validateLabel(event) {
    const label = event.target.value.trim()
    
    if (this.hasLabelErrorTarget) {
      if (label.length === 0) {
        this.labelErrorTarget.textContent = "Label is required"
        this.labelErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
      } else if (label.length > 100) {
        this.labelErrorTarget.textContent = "Label must be 100 characters or less"
        this.labelErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
      } else {
        this.labelErrorTarget.classList.add('hidden')
        event.target.classList.remove('input-error')
      }
    }
  }

  validateValue(event) {
    const value = parseInt(event.target.value)
    const isValidNumber = !isNaN(value) && value >= 0

    if (this.hasValueErrorTarget) {
      if (!isValidNumber) {
        this.valueErrorTarget.textContent = "Value must be a non-negative number"
        this.valueErrorTarget.classList.remove('hidden')
        event.target.classList.add('input-error')
        return false
      }

      if (this.responseTypeValue === 'scale') {
        if (value > 5) {
          this.valueErrorTarget.textContent = "Scale values should typically be 0-5 (0-4 is most common)"
          this.valueErrorTarget.classList.remove('hidden')
          event.target.classList.add('input-warning')
        } else if (value > (this.typicalMaxValue || 4)) {
          this.valueErrorTarget.textContent = `Values above ${this.typicalMaxValue} are uncommon for scales`
          this.valueErrorTarget.classList.remove('hidden')
          event.target.classList.add('input-warning')
        } else {
          this.valueErrorTarget.classList.add('hidden')
          event.target.classList.remove('input-error', 'input-warning')
        }
      } else {
        if (value < 0) {
          this.valueErrorTarget.textContent = "Value must be non-negative"
          this.valueErrorTarget.classList.remove('hidden')
          event.target.classList.add('input-error')
        } else {
          this.valueErrorTarget.classList.add('hidden')
          event.target.classList.remove('input-error', 'input-warning')
        }
      }
    }

    return isValidNumber
  }

  checkValueRange() {
    if (this.hasValueInputTarget && this.typicalMaxValue) {
      const value = parseInt(this.valueInputTarget.value)
      if (!isNaN(value) && value > this.typicalMaxValue) {
        this.valueInputTarget.classList.add('input-warning')
      }
    }
  }

  updateScaleLabel(event) {
    if (this.responseTypeValue !== 'scale') return

    const value = parseInt(event.target.value)
    if (isNaN(value)) return

    const scaleLabels = {
      5: "Always",
      4: "Very Often",
      3: "Often",
      2: "Sometimes",
      1: "Rarely",
      0: "Never"
    }

    if (this.hasLabelInputTarget && scaleLabels[value]) {
      // Only suggest if label is empty or matches a previous suggestion
      const currentLabel = this.labelInputTarget.value.trim()
      const isEmpty = currentLabel.length === 0
      const isSuggested = Object.values(scaleLabels).includes(currentLabel)

      if (isEmpty || isSuggested) {
        this.labelInputTarget.value = scaleLabels[value]
        this.validateLabel({ target: this.labelInputTarget })
      }
    }
  }

  quickFillScale(event) {
    event.preventDefault()
    
    if (this.responseTypeValue !== 'scale') return

    const commonOptions = [
      { label: "Always", value: 4 },
      { label: "Often", value: 3 },
      { label: "Sometimes", value: 2 },
      { label: "Rarely", value: 1 },
      { label: "Never", value: 0 }
    ]

    // Create options via AJAX
    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/question_options`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    // Create options in reverse order (so they appear as 4, 3, 2, 1, 0)
    commonOptions.reverse().forEach((option, index) => {
      setTimeout(() => {
        fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken,
            "Accept": "text/vnd.turbo-stream.html, application/json"
          },
          body: JSON.stringify({
            question_option: {
              label: option.label,
              value: option.value
            }
          })
        }).then(response => {
          if (response.ok) {
            const contentType = response.headers.get("content-type")
            if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
              return response.text().then((html) => {
                Turbo.renderStreamMessage(html)
              })
            }
          }
        }).catch(error => {
          console.error("Error creating option:", error)
        })
      }, index * 100) // Stagger requests slightly
    })

    this.showFeedback("Creating common scale options...", "info")
  }

  validateBeforeSubmit(event) {
    let isValid = true

    if (this.hasLabelInputTarget) {
      const label = this.labelInputTarget.value.trim()
      if (label.length === 0) {
        this.validateLabel({ target: this.labelInputTarget })
        isValid = false
      }
    }

    if (this.hasValueInputTarget) {
      if (!this.validateValue({ target: this.valueInputTarget })) {
        isValid = false
      }
    }

    if (!isValid) {
      event.preventDefault()
      
      // Scroll to first error
      const firstError = this.element.querySelector('.input-error')
      if (firstError) {
        firstError.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    }
  }

  handleSubmit(event) {
    // Handle Turbo Stream response
    if (event.detail.success !== false) {
      // Form was submitted successfully
      if (this.inlineValue) {
        // For inline editing, we might want to do something different
        console.log("Inline option updated successfully")
      }
    }
  }

  cancelForm(event) {
    event.preventDefault()
    
    if (this.inlineValue) {
      // For inline editing, just blur or reset
      if (this.hasLabelInputTarget) {
        this.labelInputTarget.blur()
      }
    } else {
      // For form modal, hide the form
      const formCard = this.element.closest('.card')
      if (formCard) {
        formCard.classList.add('hidden')
      }
    }
  }

  showFeedback(message, type) {
    let feedback = document.getElementById("question-option-feedback")
    if (!feedback) {
      feedback = document.createElement("div")
      feedback.id = "question-option-feedback"
      feedback.className = `alert alert-${type === "success" ? "success" : type === "error" ? "error" : "info"} fixed top-4 right-4 z-50 max-w-md shadow-lg`
      document.body.appendChild(feedback)
    } else {
      feedback.className = `alert alert-${type === "success" ? "success" : type === "error" ? "error" : "info"} fixed top-4 right-4 z-50 max-w-md shadow-lg`
    }
    
    feedback.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        ${type === "success" 
          ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />'
          : type === "error"
          ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />'
          : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />'
        }
      </svg>
      <span>${message}</span>
    `
    
    setTimeout(() => {
      if (feedback.parentNode) {
        feedback.remove()
      }
    }, 3000)
  }
}

