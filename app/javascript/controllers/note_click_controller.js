import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  visit(event) {
    // Don't trigger if clicking on a link or button
    if (event.target.closest('a') || event.target.closest('button')) {
      return
    }
    
    window.location.href = this.element.querySelector('[data-action="click->note-click#visit"]').dataset.noteClickUrl
  }
}