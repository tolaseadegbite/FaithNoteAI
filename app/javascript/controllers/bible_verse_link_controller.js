import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Bible verse link controller connected")
    // Find all Bible verse links in the content
    this.element.querySelectorAll('.bible-verse-link').forEach(link => {
      // Make sure all links have the data-turbo-frame="modal" attribute
      if (!link.hasAttribute('data-turbo-frame')) {
        link.setAttribute('data-turbo-frame', 'modal')
      }
      
      // Add click event listener
      link.addEventListener('click', this.handleVerseClick.bind(this))
    })
  }

  handleVerseClick(event) {
    const link = event.currentTarget
    
    // If it has the modal attribute, let Turbo handle it
    if (link.getAttribute('data-turbo-frame') === 'modal') {
      // Don't prevent default - let Turbo handle it
      return
    }
    
    // For links without the modal attribute (fallback), open in new tab
    event.preventDefault()
    const url = link.getAttribute('href')
    console.log(`Bible verse link clicked: ${url}`)
    window.open(url, '_blank')
  }
}