import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conversationsPanel", "chatLink", "conversationItem"]
  
  connect() {
    // Check if we're on a Bible Chat page and expand the conversations panel
    if (window.location.pathname.includes('/bible/chat')) {
      this.expandConversations()
      this.highlightActiveConversation()
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
    panel.classList.add('max-h-40') // Adjust height as needed to fit between navigation and plan card
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
  
  highlightActiveConversation() {
    // Get the current conversation ID from the URL
    const urlPath = window.location.pathname
    const matches = urlPath.match(/\/bible\/chat\/conversations\/(\d+)/)
    const currentConversationId = matches ? matches[1] : null
    
    // Only proceed if we have conversation items and are on a conversation page
    if (!this.hasConversationItemTarget || !currentConversationId) return
    
    // Update the active state for all conversation items
    this.conversationItemTargets.forEach(item => {
      const conversationId = item.dataset.conversationId
      
      if (conversationId === currentConversationId) {
        item.classList.add('bg-green-100', 'dark:bg-green-900/30', 'text-green-700', 'dark:text-green-400')
        item.classList.remove('text-gray-700', 'dark:text-gray-300', 'hover:bg-gray-100', 'dark:hover:bg-gray-700')
      } else {
        item.classList.remove('bg-green-100', 'dark:bg-green-900/30', 'text-green-700', 'dark:text-green-400')
        item.classList.add('text-gray-700', 'dark:text-gray-300', 'hover:bg-gray-100', 'dark:hover:bg-gray-700')
      }
    })
  }
}