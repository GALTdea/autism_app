import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "list", "positionBadge"]
  static values = { 
    updateUrl: String,
    questionId: Number,
    profileDomainId: Number
  }

  connect() {
    this.draggedElement = null
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    this.itemTargets.forEach((item) => {
      item.setAttribute("draggable", "true")
      
      item.addEventListener("dragstart", this.handleDragStart.bind(this))
      item.addEventListener("dragover", this.handleDragOver.bind(this))
      item.addEventListener("drop", this.handleDrop.bind(this))
      item.addEventListener("dragend", this.handleDragEnd.bind(this))
    })
  }

  handleDragStart(event) {
    this.draggedElement = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50", "border-primary", "border-2")
  }

  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    
    const afterElement = this.getDragAfterElement(this.listTarget, event.clientY)
    const dragging = this.draggedElement
    
    if (afterElement == null) {
      this.listTarget.appendChild(dragging)
    } else {
      this.listTarget.insertBefore(dragging, afterElement)
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
    
    this.itemTargets.forEach((item, index) => {
      const optionId = item.dataset.optionId
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
    this.itemTargets.forEach((item, index) => {
      // Update position badge if it exists
      const badge = item.querySelector("[data-sortable-options-target='positionBadge']")
      if (badge) {
        badge.textContent = index + 1
      }
      
      // Also update any badge with class-based selector
      const badgeByClass = item.querySelector(".badge.badge-neutral")
      if (badgeByClass && badgeByClass.textContent.match(/^\d+$/)) {
        badgeByClass.textContent = index + 1
      }
    })
  }

  async saveOrder(optionPositions) {
    const url = this.updateUrlValue || 
                `/admin/profile_domains/${this.profileDomainIdValue}/questions/${this.questionIdValue}/question_options/reorder`
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

  showFeedback(message, type) {
    let feedback = document.getElementById("sortable-options-feedback")
    if (!feedback) {
      feedback = document.createElement("div")
      feedback.id = "sortable-options-feedback"
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
      <button onclick="this.parentElement.remove()" class="btn btn-sm btn-circle btn-ghost">✕</button>
    `
    
    setTimeout(() => {
      if (feedback.parentNode) {
        feedback.remove()
      }
    }, 3000)
  }
}

