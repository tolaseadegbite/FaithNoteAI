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
    console.log("Translation change triggered", event.currentTarget.dataset.translation)
    
    if (!this.hasTranslationFieldTarget || !this.hasTranslationDisplayTarget) {
      console.error("Missing required targets for translation change")
      return
    }
    
    const newTranslation = event.currentTarget.dataset.translation
    if (!newTranslation) return
    
    console.log("Updating translation to:", newTranslation)
    
    // Update hidden field and display
    this.translationFieldTarget.value = newTranslation
    this.translationDisplayTarget.textContent = newTranslation
    
    // Update form action URL
    const form = this.element
    const url = new URL(form.action)
    url.searchParams.set('translation', newTranslation)
    form.action = url.toString()
    
    // Update translation link states
    const links = document.querySelectorAll('[data-translation]')
    links.forEach(link => {
      const translation = link.dataset.translation
      if (translation === newTranslation) {
        link.classList.add('bg-green-50', 'dark:bg-green-900/10', 'text-green-600', 'dark:text-green-500')
        link.classList.remove('text-gray-700', 'dark:text-gray-200', 'hover:bg-gray-50', 'dark:hover:bg-gray-700')
      } else {
        link.classList.remove('bg-green-50', 'dark:bg-green-900/10', 'text-green-600', 'dark:text-green-500')
        link.classList.add('text-gray-700', 'dark:text-gray-200', 'hover:bg-gray-50', 'dark:hover:bg-gray-700')
      }
    })
  }
}