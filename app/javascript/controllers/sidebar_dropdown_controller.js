import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Close dropdown when clicking outside
    document.addEventListener('click', this.outsideClick.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.outsideClick.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle('hidden')
  }
  
  outsideClick(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains('hidden')) {
      this.menuTarget.classList.add('hidden')
    }
  }
}