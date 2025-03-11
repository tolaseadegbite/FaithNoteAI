import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textButton", "audioButton", "textForm", "audioForm"]
  
  connect() {
    // Default to text entry
    this.selectType({ currentTarget: this.textButtonTarget })
  }
  
  selectType(event) {
    const type = event.currentTarget.dataset.type
    
    // Update button styles
    this.textButtonTarget.classList.remove("bg-green-50", "dark:bg-green-900/10", "text-green-600", "dark:text-green-500")
    this.audioButtonTarget.classList.remove("bg-green-50", "dark:bg-green-900/10", "text-green-600", "dark:text-green-500")
    
    if (type === "text") {
      this.textButtonTarget.classList.add("bg-green-50", "dark:bg-green-900/10", "text-green-600", "dark:text-green-500")
      this.textFormTarget.classList.remove("hidden")
      this.audioFormTarget.classList.add("hidden")
    } else {
      this.audioButtonTarget.classList.add("bg-green-50", "dark:bg-green-900/10", "text-green-600", "dark:text-green-500")
      this.audioFormTarget.classList.remove("hidden")
      this.textFormTarget.classList.add("hidden")
    }
  }
}