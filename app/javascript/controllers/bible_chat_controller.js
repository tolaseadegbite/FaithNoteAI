import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    
    // Set up a mutation observer to detect when messages are added
    this.setupMessageObserver()
  }
  
  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
  
  setupMessageObserver() {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          this.scrollToBottom()
        }
      })
    })
    
    observer.observe(this.element, { childList: true, subtree: true })
  }
}