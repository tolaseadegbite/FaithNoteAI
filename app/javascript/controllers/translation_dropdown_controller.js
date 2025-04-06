import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeIfClickedOutside)
    // Close dropdown when another dropdown opens
    document.addEventListener("dropdown:opened", this.closeDropdown)
  }

  disconnect() {
    document.removeEventListener("click", this.closeIfClickedOutside)
    document.removeEventListener("dropdown:opened", this.closeDropdown)
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // Dispatch event to close other dropdowns
    const event = new CustomEvent("dropdown:opened", { bubbles: true })
    this.element.dispatchEvent(event)
    
    // Position the dropdown relative to the button
    const buttonRect = this.buttonTarget.getBoundingClientRect()
    this.menuTarget.style.top = `${buttonRect.bottom + window.scrollY + 8}px`
    this.menuTarget.style.left = `${buttonRect.left + window.scrollX}px`
    
    // Open this dropdown
    this.menuTarget.classList.remove("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  closeDropdown = () => {
    if (!this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  closeIfClickedOutside = (event) => {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}