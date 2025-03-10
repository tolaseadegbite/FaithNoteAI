import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    // Close any open dropdowns when the controller connects
    this.closeDropdown()
    
    // Add event listener to close dropdown when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
    
    // Add event listener for Turbo navigation
    document.addEventListener('turbo:before-visit', this.closeDropdown.bind(this))
  }
  
  disconnect() {
    // Remove event listeners when controller disconnects
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
    document.removeEventListener('turbo:before-visit', this.closeDropdown.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    const isHidden = this.menuTarget.classList.contains('hidden')
    
    // Close all other dropdowns first
    document.querySelectorAll('[data-dropdown-target="menu"]').forEach(menu => {
      if (menu !== this.menuTarget) {
        menu.classList.add('hidden')
      }
    })
    
    // Toggle this dropdown
    if (isHidden) {
      this.menuTarget.classList.remove('hidden')
    } else {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  closeDropdown() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }
}