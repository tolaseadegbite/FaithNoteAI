import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]
  
  connect() {
    console.log("Bible search controller connected")
  }
  
  checkReference() {
    const value = this.inputTarget.value
    
    // Check if input looks like a Bible reference
    if (value.match(/^([1-3]?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$/)) {
      this.inputTarget.classList.add("bg-green-50", "dark:bg-green-900/10")
    } else {
      this.inputTarget.classList.remove("bg-green-50", "dark:bg-green-900/10")
    }
  }
  
  validateBeforeSubmit(event) {
    const query = this.inputTarget.value.trim()
    
    if (!query) {
      event.preventDefault()
      // Add visual feedback
      this.inputTarget.classList.add("border-red-500")
      setTimeout(() => {
        this.inputTarget.classList.remove("border-red-500")
      }, 1500)
    }
  }
}