import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "messages"]
  
  connect() {
    this.scrollToBottom()
    
    // Focus the input field when the controller connects
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
    
    // Set up a mutation observer to detect when messages are added
    this.setupMessageObserver()
    
    // Initialize the input field height
    if (this.hasInputTarget) {
      this.resize()
    }
  }
  
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
  
  setupMessageObserver() {
    if (this.hasMessagesTarget) {
      const observer = new MutationObserver(() => {
        this.scrollToBottom()
      })
      
      observer.observe(this.messagesTarget, { 
        childList: true, 
        subtree: true 
      })
    }
  }
  
  submit(event) {
    // Only prevent default if it's the Enter key without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      
      // Don't submit if the input is empty
      if (this.inputTarget.value.trim() === "") {
        return
      }
      
      // Submit the form using Turbo
      this.formTarget.requestSubmit()
    }
  }
  
  // Auto-resize the input field as the user types
  resize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = `${Math.min(input.scrollHeight, 150)}px` // Limit to 150px max height
  }
}