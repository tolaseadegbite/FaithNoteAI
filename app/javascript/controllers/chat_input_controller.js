import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    this.resize()
  }
  
  submitOnEnter(event) {
    // Only submit if it's the Enter key without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      
      // Don't submit if the input is empty
      if (this.inputTarget.value.trim() === "") {
        return
      }
      
      // Submit the form
      this.element.requestSubmit()
    }
  }
  
  resize() {
    const input = this.inputTarget
    
    // Reset height to auto to get the correct scrollHeight
    input.style.height = 'auto'
    
    // Set the height to match content (with a max height)
    const newHeight = Math.min(input.scrollHeight, 150)
    input.style.height = `${newHeight}px`
  }

  updateTitle(event) {
    if (event.target.form.querySelector('input[name="title"]')) {
      event.target.form.querySelector('input[name="title"]').value = event.target.value;
    }
  }
}