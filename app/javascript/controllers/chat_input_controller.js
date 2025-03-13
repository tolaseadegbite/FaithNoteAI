import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "translationField", "translationDisplay"]

  connect() {
    this.resize()
    
    // Initialize title update if needed
    if (this.hasInputTarget && this.element.querySelector('input[name="title"]')) {
      this.updateTitle()
    }
  }

  resize() {
    if (this.hasInputTarget) {
      const input = this.inputTarget
      input.style.height = "auto"
      input.style.height = (input.scrollHeight) + "px"
    }
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      event.target.form.requestSubmit()
    }
  }

  updateTitle() {
    const titleField = this.element.querySelector('input[name="title"]')
    const messageField = this.inputTarget
    
    if (titleField && messageField) {
      titleField.value = messageField.value
    }
  }

  changeTranslation(event) {
    event.preventDefault()
    
    if (!this.hasTranslationFieldTarget || !this.hasTranslationDisplayTarget) {
      console.error("Missing required targets for translation change")
      return
    }
    
    const newTranslation = event.currentTarget.dataset.translation
    this.translationFieldTarget.value = newTranslation
    this.translationDisplayTarget.textContent = newTranslation
    
    // Update all translation links
    const links = this.element.querySelectorAll('[data-chat-input-translation]')
    links.forEach(link => {
      const translation = link.dataset.chatInputTranslation
      if (translation === newTranslation) {
        link.classList.add('text-green-600', 'dark:text-green-400', 'bg-green-50', 'dark:bg-green-900/10')
        link.classList.remove('text-gray-700', 'dark:text-gray-200')
      } else {
        link.classList.remove('text-green-600', 'dark:text-green-400', 'bg-green-50', 'dark:bg-green-900/10')
        link.classList.add('text-gray-700', 'dark:text-gray-200')
      }
    })
  }
}