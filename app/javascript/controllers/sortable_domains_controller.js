import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "list"]
  static values = { 
    updateUrl: String,
    assessmentId: Number
  }

  connect() {
    this.draggedElement = null
    this.eventListeners = new Map() // Track event listeners for cleanup
    this.settingUp = false
    this.reconnectTimeout = null
    this.setupDragAndDrop()
    
    // Listen for Turbo Stream updates to reinitialize after DOM changes
    this.boundHandleStreamRender = this.handleStreamRender.bind(this)
    document.addEventListener("turbo:after-stream-render", this.boundHandleStreamRender)
  }

  disconnect() {
    this.cleanupDragAndDrop()
    document.removeEventListener("turbo:after-stream-render", this.boundHandleStreamRender)
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout)
      this.reconnectTimeout = null
    }
  }

  handleStreamRender(event) {
    // Re-setup after any Turbo Stream renders
    // The debouncing in scheduleReconnect will prevent excessive calls
    this.scheduleReconnect()
  }

  scheduleReconnect() {
    // Debounce reconnection to avoid multiple calls
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout)
    }
    this.reconnectTimeout = setTimeout(() => {
      if (this.hasListTarget && this.hasItemTarget) {
        this.setupDragAndDrop()
      }
      this.reconnectTimeout = null
    }, 50)
  }

  itemTargetConnected(item) {
    // When a new item target is connected (after Turbo Stream update)
    // Schedule a re-setup, but debounce it to avoid multiple calls
    this.scheduleReconnect()
  }
  
  itemTargetDisconnected(item) {
    // Clean up listeners when item is removed
    if (this.eventListeners.has(item)) {
      const listeners = this.eventListeners.get(item)
      listeners.forEach(({ event, handler }) => {
        item.removeEventListener(event, handler)
      })
      this.eventListeners.delete(item)
    }
  }

  cleanupDragAndDrop() {
    // Remove all event listeners
    this.eventListeners.forEach((listeners, item) => {
      listeners.forEach(({ event, handler }) => {
        item.removeEventListener(event, handler)
      })
    })
    this.eventListeners.clear()
  }

  setupDragAndDrop() {
    if (this.settingUp) return // Prevent re-entrant calls
    this.settingUp = true
    
    try {
      // Clean up existing listeners first
      this.cleanupDragAndDrop()
      
      // Only proceed if we have targets
      if (!this.hasListTarget || !this.hasItemTarget) {
        return
      }
      
      this.itemTargets.forEach((item, index) => {
        // Skip if already has listeners
        if (this.eventListeners.has(item)) {
          return
        }
        
        item.setAttribute("draggable", "true")
        item.dataset.index = index
        
        // Create bound handlers
        const dragStartHandler = this.handleDragStart.bind(this)
        const dragOverHandler = this.handleDragOver.bind(this)
        const dropHandler = this.handleDrop.bind(this)
        const dragEndHandler = this.handleDragEnd.bind(this)
        
        // Store handlers for cleanup
        const listeners = [
          { event: "dragstart", handler: dragStartHandler },
          { event: "dragover", handler: dragOverHandler },
          { event: "drop", handler: dropHandler },
          { event: "dragend", handler: dragEndHandler }
        ]
        this.eventListeners.set(item, listeners)
        
        // Add event listeners
        item.addEventListener("dragstart", dragStartHandler)
        item.addEventListener("dragover", dragOverHandler)
        item.addEventListener("drop", dropHandler)
        item.addEventListener("dragend", dragEndHandler)
      })
    } finally {
      this.settingUp = false
    }
  }

  handleDragStart(event) {
    this.draggedElement = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/html", event.currentTarget.outerHTML)
    event.currentTarget.classList.add("opacity-50", "border-primary")
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
    event.currentTarget.classList.remove("opacity-50", "border-primary")
    
    // Update positions and save
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
    const domainPositions = {}
    
    this.itemTargets.forEach((item, index) => {
      const domainId = item.dataset.domainId
      if (domainId) {
        domainPositions[domainId] = index
      }
    })

    // Send update to server
    this.saveOrder(domainPositions)
  }

  async saveOrder(domainPositions) {
    const url = this.updateUrlValue
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: JSON.stringify({
          domain_positions: domainPositions
        })
      })

      if (response.ok) {
        // Check if response is Turbo Stream
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          // Let Turbo handle the stream
          return response.text().then((html) => {
            Turbo.renderStreamMessage(html)
          })
        } else {
          // JSON response fallback
          const data = await response.json()
          this.showFeedback(data.message || "Domain order saved successfully!", "success")
          
          // Update position numbers in the DOM
          this.updatePositionNumbers()
        }
      } else {
        throw new Error("Failed to save order")
      }
    } catch (error) {
      console.error("Error saving domain order:", error)
      this.showFeedback("Failed to save domain order. Please try again.", "error")
    }
  }

  updatePositionNumbers() {
    // Update position numbers after successful reorder
    this.itemTargets.forEach((item, index) => {
      const positionBadge = item.querySelector(".bg-primary")
      if (positionBadge) {
        positionBadge.textContent = index + 1
      }
    })
  }

  showFeedback(message, type) {
    // Create or update feedback element
    let feedback = document.getElementById("sortable-feedback")
    if (!feedback) {
      feedback = document.createElement("div")
      feedback.id = "sortable-feedback"
      feedback.className = "alert alert-" + (type === "success" ? "success" : "error") + " fixed top-4 right-4 z-50 max-w-md"
      document.body.appendChild(feedback)
    } else {
      feedback.className = "alert alert-" + (type === "success" ? "success" : "error") + " fixed top-4 right-4 z-50 max-w-md"
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
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
      if (feedback.parentNode) {
        feedback.remove()
      }
    }, 3000)
  }
}

