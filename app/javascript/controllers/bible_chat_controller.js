import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "messages", "translationSelector"]
  
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
  
  setupMessageObserver() {
    if (this.hasMessagesTarget) {
      this.observer = new MutationObserver(() => {
        this.scrollToBottom()
      })
      
      this.observer.observe(this.messagesTarget, {
        childList: true,
        subtree: true
      })
    }
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
  
  handleKeydown(event) {
    // Submit the form when Enter is pressed without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }
  
  resize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = (input.scrollHeight) + "px"
  }
  
  updateTranslation(event) {
    event.preventDefault()
    
    // Update the translation in the UI
    if (this.hasTranslationSelectorTarget) {
      const translation = event.currentTarget.dataset.translation
      
      // Update all form actions to include the new translation
      const forms = document.querySelectorAll('form')
      forms.forEach(form => {
        const url = new URL(form.action)
        url.searchParams.set('translation', translation)
        form.action = url.toString()
      })
    }
  }
}