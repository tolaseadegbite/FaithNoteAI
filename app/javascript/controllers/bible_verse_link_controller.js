import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Find all Bible verse links in the content
    this.element.querySelectorAll('.bible-verse-link').forEach(link => {
      // Add click event listener
      link.addEventListener('click', this.handleVerseClick.bind(this))
    })
  }

  handleVerseClick(event) {
    // We can use the default browser behavior for now
    // but this gives us a hook to add custom behavior later if needed
    // For example, we could open the verse in a modal instead of a new tab
    
    // If we want to track analytics or add other functionality:
    const link = event.currentTarget
    const url = link.getAttribute('href')
    console.log(`Bible verse link clicked: ${url}`)
    
    // Let the default behavior continue (opening the link)
  }
}