import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { open: Boolean }

  connect() {
    // Close tooltip when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
    // Listen for custom event to close other tooltips
    document.addEventListener("tooltip:close-others", this.closeIfNotSource.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
    document.removeEventListener("tooltip:close-others", this.closeIfNotSource.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    
    // Close all other tooltips first
    document.dispatchEvent(new CustomEvent("tooltip:close-others", {
      detail: { sourceId: this.element.id }
    }))
    
    // Toggle this tooltip
    this.contentTarget.classList.toggle("hidden")
  }

  closeIfNotSource(event) {
    // Only close if this isn't the tooltip that triggered the event
    if (this.element.id !== event.detail.sourceId && !this.contentTarget.classList.contains("hidden")) {
      this.contentTarget.classList.add("hidden")
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && !this.contentTarget.classList.contains("hidden")) {
      this.contentTarget.classList.add("hidden")
    }
  }
}