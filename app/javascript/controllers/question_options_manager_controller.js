import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "addButton",
    "addForm",
    "optionsList",
    "optionRow",
    "labelField",
    "valueField",
    "labelInput",
    "valueInput",
    "infoAlert",
    "infoTitle",
    "infoText",
    "emptyState"
  ]

  static values = {
    questionId: Number,
    responseType: String,
    profileDomainId: Number
  }

  connect() {
    console.log("Question Options Manager connected")
    this.setupSortable()
  }

  setupSortable() {
    // Set up drag and drop if options exist
    if (this.hasOptionsListTarget) {
      this.optionRowTargets.forEach((row) => {
        row.setAttribute("draggable", "true")
        
        row.addEventListener("dragstart", this.handleDragStart.bind(this))
        row.addEventListener("dragover", this.handleDragOver.bind(this))
        row.addEventListener("drop", this.handleDrop.bind(this))
        row.addEventListener("dragend", this.handleDragEnd.bind(this))
      })
    }
  }

  handleDragStart(event) {
    this.draggedElement = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50", "border-primary", "border-2")
  }

  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    
    const afterElement = this.getDragAfterElement(this.optionsListTarget, event.clientY)
    const dragging = this.draggedElement
    
    if (afterElement == null) {
      this.optionsListTarget.appendChild(dragging)
    } else {
      this.optionsListTarget.insertBefore(dragging, afterElement)
    }
  }

  handleDrop(event) {
    event.preventDefault()
    return false
  }

  handleDragEnd(event) {
    event.currentTarget.classList.remove("opacity-50", "border-primary", "border-2")
    this.updatePositions()
  }

  getDragAfterElement(container, y) {
    const draggableElements = [...container.querySelectorAll("[draggable='true']:not(.opacity-50)")]
    
    return draggableElements.reduce((closest, child) => {
      const box = child.getBoundingClientRect()
      const offset = y - box.top - box.height / 2
      
      if (offset < 0 && offset > closest.offset) {
        return { offset: offset, element: child }
      } else {
        return closest
      }
    }, { offset: Number.NEGATIVE_INFINITY }).element
  }

  updatePositions() {
    const optionPositions = {}
    
    this.optionRowTargets.forEach((row, index) => {
      const optionId = row.dataset.optionId
      if (optionId) {
        optionPositions[optionId] = index
      }
    })

    // Update position badges
    this.updatePositionBadges()

    // Save to server
    this.saveOrder(optionPositions)
  }

  updatePositionBadges() {
    this.optionRowTargets.forEach((row, index) => {
      const badge = row.querySelector("[data-sortable-options-target='positionBadge']")
      if (badge) {
        badge.textContent = index + 1
      }
    })
  }

  async saveOrder(optionPositions) {
    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/question_options/reorder`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html, application/json"
        },
        body: JSON.stringify({
          option_positions: optionPositions
        })
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          return response.text().then((html) => {
            Turbo.renderStreamMessage(html)
          })
        } else {
          const data = await response.json()
          this.showFeedback(data.message || "Option order saved successfully!", "success")
        }
      } else {
        throw new Error("Failed to save order")
      }
    } catch (error) {
      console.error("Error saving option order:", error)
      this.showFeedback("Failed to save option order. Please try again.", "error")
    }
  }

  showAddForm() {
    this.addFormTarget.classList.remove("hidden")
    this.addButtonTarget.classList.add("hidden")
    if (this.hasLabelInputTarget) {
      this.labelInputTarget.focus()
    }
  }

  hideAddForm() {
    this.addFormTarget.classList.add("hidden")
    this.addButtonTarget.classList.remove("hidden")
    // Reset form
    const form = this.addFormTarget.querySelector("form")
    if (form) {
      form.reset()
    }
  }

  handleSubmit(event) {
    // Hide form after successful submission
    if (event.detail.success !== false) {
      this.hideAddForm()
    }
  }

  async updateOption(event) {
    const field = event.target
    const optionId = field.dataset.optionId
    const fieldType = field === field.closest('[data-question-options-manager-target="labelField"]') ? 'label' : 'value'
    const value = field.value

    // Validate value for scale questions
    if (fieldType === 'value' && this.responseTypeValue === 'scale') {
      const numValue = parseInt(value)
      if (isNaN(numValue) || numValue < 0) {
        field.classList.add("input-error")
        this.showFeedback("Value must be a non-negative number", "error")
        return
      }
    }

    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/question_options/${optionId}`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    const params = {}
    params[fieldType] = fieldType === 'value' ? parseInt(value) : value

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html, application/json"
        },
        body: JSON.stringify({
          question_option: params
        })
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          return response.text().then((html) => {
            Turbo.renderStreamMessage(html)
          })
        } else {
          this.showFeedback("Option updated successfully", "success")
        }
        field.classList.remove("input-error")
      } else {
        throw new Error("Failed to update option")
      }
    } catch (error) {
      console.error("Error updating option:", error)
      field.classList.add("input-error")
      this.showFeedback("Failed to update option. Please try again.", "error")
    }
  }

  async deleteOption(event) {
    const button = event.currentTarget
    const optionId = button.dataset.optionId
    
    if (!confirm("Are you sure you want to delete this option? This action cannot be undone.")) {
      return
    }

    const url = `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/question_options/${optionId}`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    try {
      const response = await fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html, application/json"
        }
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          return response.text().then((html) => {
            Turbo.renderStreamMessage(html)
          })
        } else {
          // Remove from DOM if not Turbo Stream
          const row = button.closest('[data-question-options-manager-target="optionRow"]')
          if (row) {
            row.remove()
            this.updatePositions()
          }
          this.showFeedback("Option deleted successfully", "success")
        }
      } else {
        const data = await response.json()
        throw new Error(data.message || "Failed to delete option")
      }
    } catch (error) {
      console.error("Error deleting option:", error)
      this.showFeedback(error.message || "Failed to delete option. It may have existing answers.", "error")
    }
  }

  showFeedback(message, type) {
    let feedback = document.getElementById("question-options-feedback")
    if (!feedback) {
      feedback = document.createElement("div")
      feedback.id = "question-options-feedback"
      feedback.className = `alert alert-${type === "success" ? "success" : "error"} fixed top-4 right-4 z-50 max-w-md shadow-lg`
      document.body.appendChild(feedback)
    } else {
      feedback.className = `alert alert-${type === "success" ? "success" : "error"} fixed top-4 right-4 z-50 max-w-md shadow-lg`
    }
    
    feedback.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        ${type === "success" 
          ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />'
          : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />'
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

