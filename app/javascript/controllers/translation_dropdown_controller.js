import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]
  
  connect() {
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }
  
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.menuTarget.classList.toggle('hidden')
  }
  
  handleOutsideClick(event) {
    if (this.hasMenuTarget && !this.menuTarget.classList.contains('hidden')) {
      if (!this.menuTarget.contains(event.target) && !this.buttonTarget.contains(event.target)) {
        this.menuTarget.classList.add('hidden')
      }
    }
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }
}