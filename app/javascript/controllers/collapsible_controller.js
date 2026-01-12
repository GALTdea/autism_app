import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "button", "icon"]
  static values = { 
    open: { type: Boolean, default: false }
  }

  connect() {
    this.updateDisplay()
  }

  toggle() {
    this.openValue = !this.openValue
    this.updateDisplay()
  }

  openValueChanged() {
    this.updateDisplay()
  }

  updateDisplay() {
    if (this.hasContentTarget) {
      if (this.openValue) {
        this.contentTarget.classList.remove("hidden")
        if (this.hasButtonTarget) {
          this.buttonTarget.setAttribute("aria-expanded", "true")
        }
        if (this.hasIconTarget) {
          this.iconTarget.classList.add("rotate-180")
        }
      } else {
        this.contentTarget.classList.add("hidden")
        if (this.hasButtonTarget) {
          this.buttonTarget.setAttribute("aria-expanded", "false")
        }
        if (this.hasIconTarget) {
          this.iconTarget.classList.remove("rotate-180")
        }
      }
    }
  }
}
