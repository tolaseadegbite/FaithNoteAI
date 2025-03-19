import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.preserveScrollPosition()
  }

  preserveScrollPosition() {
    const container = this.containerTarget
    let previousScrollHeight = container.scrollHeight
    
    const observer = new MutationObserver(() => {
      const newScrollHeight = container.scrollHeight
      const diff = newScrollHeight - previousScrollHeight
      if (diff > 0) {
        container.scrollTop += diff
      }
      previousScrollHeight = newScrollHeight
    })

    observer.observe(container, {
      childList: true,
      subtree: true
    })
  }
}