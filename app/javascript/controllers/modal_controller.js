// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    // Store the current scroll position before opening the modal
    this.scrollPosition = window.pageYOffset || document.documentElement.scrollTop
    
    this.open()
    // needed because ESC key does not trigger close event
    this.element.addEventListener("close", this.enableBodyScroll.bind(this))

    this.element.addEventListener('turbo:submit-end', () => {
      Array.from(document.getElementsByClassName('close-modal-btn')).forEach((btn) => {
        btn.click();
      });
    });
  }

  disconnect() {
    this.element.removeEventListener("close", this.enableBodyScroll.bind(this))
  }

  // hide modal on successful form submission
  // data-action="turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.close()
    }
  }

  open() {
    // Use fixed positioning instead of overflow hidden to prevent scroll jump
    this.element.showModal()
    
    // Prevent body scroll without changing position
    document.body.style.position = 'fixed'
    document.body.style.top = `-${this.scrollPosition}px`
    document.body.style.width = '100%'
    document.body.classList.add('overflow-hidden')
  }

  close() {
    this.element.close()
    // clean up modal content
    const frame = document.getElementById('modal')
    frame.removeAttribute("src")
    frame.innerHTML = ""
    
    this.enableBodyScroll()
  }

  enableBodyScroll() {
    document.body.classList.remove('overflow-hidden')
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.width = ''
    
    // Restore scroll position
    window.scrollTo(0, this.scrollPosition)
  }

  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}