import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conversationsPanel", "chatLink"]
  
  connect() {
    // Check if we're on a Bible Chat page and expand the conversations panel
    if (window.location.pathname.includes('/bible/chat')) {
      this.expandConversations()
    }
  }
  
  toggleConversations(event) {
    // Don't prevent default navigation when clicking the main link
    const panel = this.conversationsPanelTarget
    
    if (panel.classList.contains('max-h-0')) {
      this.expandConversations()
    } else {
      this.collapseConversations()
    }
  }
  
  expandConversations() {
    const panel = this.conversationsPanelTarget
    panel.classList.remove('max-h-0')
    panel.classList.add('max-h-96') // Adjust height as needed
  }
  
  collapseConversations() {
    const panel = this.conversationsPanelTarget
    panel.classList.remove('max-h-96')
    panel.classList.add('max-h-0')
  }

  preventPropagation(event) {
    // Prevent the click from bubbling up to parent elements
    event.stopPropagation()
  }
}