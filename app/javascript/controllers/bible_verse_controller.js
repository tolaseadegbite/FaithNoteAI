import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "reference"]
  
  connect() {
    // Check if we need to highlight a specific verse
    const urlParams = new URLSearchParams(window.location.search)
    const highlightVerse = urlParams.get('highlight')
    
    if (highlightVerse && this.element.id === `verse-${highlightVerse}`) {
      this.element.classList.add("bg-green-50", "dark:bg-green-900/10")
      setTimeout(() => {
        this.element.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }, 300)
    }
  }
  
  copy() {
    const reference = this.referenceTarget.textContent
    const content = this.contentTarget.textContent
    const textToCopy = `${reference} - ${content}`
    
    navigator.clipboard.writeText(textToCopy).then(() => {
      // Show a temporary notification
      const notification = document.createElement('div')
      notification.textContent = 'Copied to clipboard!'
      notification.className = 'fixed bottom-4 right-4 bg-green-500 text-white px-4 py-2 rounded shadow-lg z-50'
      document.body.appendChild(notification)
      
      setTimeout(() => {
        notification.remove()
      }, 2000)
    })
  }
}