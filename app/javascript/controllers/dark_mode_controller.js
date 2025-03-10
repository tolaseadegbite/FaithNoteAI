import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["darkIcon", "lightIcon", "toggle"]
  
  connect() {
    // Set initial state based on localStorage or system preference
    if (localStorage.getItem('color-theme') === 'dark' || 
        (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark')
      this.showLightIcon()
    } else {
      document.documentElement.classList.remove('dark')
      this.showDarkIcon()
    }
  }
  
  toggle() {
    // If dark mode is currently active
    if (document.documentElement.classList.contains('dark')) {
      // Switch to light mode
      document.documentElement.classList.remove('dark')
      localStorage.setItem('color-theme', 'light')
      this.showDarkIcon()
    } else {
      // Switch to dark mode
      document.documentElement.classList.add('dark')
      localStorage.setItem('color-theme', 'dark')
      this.showLightIcon()
    }
  }
  
  showDarkIcon() {
    if (this.hasDarkIconTarget && this.hasLightIconTarget) {
      this.darkIconTarget.classList.remove('hidden')
      this.lightIconTarget.classList.add('hidden')
    }
  }
  
  showLightIcon() {
    if (this.hasDarkIconTarget && this.hasLightIconTarget) {
      this.darkIconTarget.classList.add('hidden')
      this.lightIconTarget.classList.remove('hidden')
    }
  }
}