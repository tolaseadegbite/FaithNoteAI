import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  
  connect() {
    // Check if we need to update the UI based on status
    if (this.hasStatusTarget && this.statusTarget.dataset.status === "open") {
      this.openViewer()
    }
  }
  
  showVerse(event) {
    // Prevent default link behavior
    if (event) {
      event.preventDefault()
    }
    
    // Let Turbo handle the frame update
    // The link already has data-turbo-frame="verse_viewer"
    
    // Open the appropriate viewer based on screen size
    this.openViewer()
  }
  
  openViewer() {
    const backdrop = document.getElementById('verse_backdrop')
    const sidePanel = document.getElementById('verse_side_panel')
    const bottomSheet = document.getElementById('verse_bottom_sheet')
    
    // Show backdrop
    if (backdrop) backdrop.classList.remove('hidden')
    
    // Determine if we're on mobile or desktop
    const isMobile = window.innerWidth < 1024 // lg breakpoint in Tailwind
    
    if (isMobile) {
      // Show bottom sheet on mobile
      if (bottomSheet) {
        bottomSheet.classList.remove('translate-y-full')
        bottomSheet.classList.add('translate-y-0')
      }
    } else {
      // Show side panel on desktop
      if (sidePanel) {
        sidePanel.classList.remove('translate-x-full')
        sidePanel.classList.add('translate-x-0')
      }
    }
  }
  
  closeViewer() {
    const backdrop = document.getElementById('verse_backdrop')
    const sidePanel = document.getElementById('verse_side_panel')
    const bottomSheet = document.getElementById('verse_bottom_sheet')
    
    // Hide backdrop
    if (backdrop) backdrop.classList.add('hidden')
    
    // Hide both viewers
    if (sidePanel) {
      sidePanel.classList.remove('translate-x-0')
      sidePanel.classList.add('translate-x-full')
    }
    
    if (bottomSheet) {
      bottomSheet.classList.remove('translate-y-0')
      bottomSheet.classList.add('translate-y-full')
    }
    
    // Update status
    if (this.hasStatusTarget) {
      this.statusTarget.dataset.status = "closed"
    }
  }
}