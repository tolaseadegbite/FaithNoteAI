import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]

  connect() {
    this.updateTimeAgo()
    this.refreshTimer = setInterval(() => this.updateTimeAgo(), 60000) // Update every minute
  }

  disconnect() {
    clearInterval(this.refreshTimer)
  }

  updateTimeAgo() {
    this.timeTargets.forEach(element => {
      const timestamp = parseInt(element.dataset.timestamp)
      if (isNaN(timestamp)) {
        element.textContent = "Invalid time"
        return
      }

      const seconds = Math.floor((new Date().getTime() - timestamp * 1000) / 1000)

      let interval = seconds / 31536000;
      if (interval > 1) {
        element.textContent = Math.floor(interval) + " years ago"
        return
      }
      interval = seconds / 2592000;
      if (interval > 1) {
        element.textContent = Math.floor(interval) + " months ago"
        return
      }
      interval = seconds / 86400;
      if (interval > 1) {
        element.textContent = Math.floor(interval) + " days ago"
        return
      }
      interval = seconds / 3600;
      if (interval > 1) {
        element.textContent = Math.floor(interval) + " hours ago"
        return
      }
      interval = seconds / 60;
      if (interval > 1) {
        element.textContent = Math.floor(interval) + " minutes ago"
        return
      }
      if (seconds < 10) {
        element.textContent = "just now"
      } else {
        element.textContent = Math.floor(seconds) + " seconds ago"
      }
    })
  }
}
