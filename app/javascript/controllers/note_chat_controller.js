import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form"]
  
  connect() {
    this.scrollToBottom()
    
    // Focus the input field when the controller connects
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
    
    // Set up a mutation observer to detect when messages are added or changed
    this.setupMessageObserver()
  }
  
  setupMessageObserver() {
    if (this.hasMessagesTarget) {
      // Create a mutation observer to watch for changes to the messages container
      this.observer = new MutationObserver(() => {
        this.scrollToBottom()
      })
      
      // Start observing the messages container for changes
      this.observer.observe(this.messagesTarget, {
        childList: true,    // Watch for added/removed children
        subtree: true,      // Watch the entire subtree
        characterData: true // Watch for text changes
      })
    }
  }
  
  disconnect() {
    // Clean up the observer when the controller disconnects
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
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
      
      // Clear the input field
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
      
      // Focus back on the input
      this.inputTarget.focus()
    }
  }
  
  // Auto-resize the input field as the user types
  resize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = `${input.scrollHeight}px`
  }
}