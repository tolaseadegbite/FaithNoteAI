import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["transcription", "summary", "button", "progress", "spinner"]
  
  connect() {
    console.log("Summary controller connected")
    this.progress = 0
  }
  
  async generate(event) {
    event.preventDefault()
    
    const button = this.buttonTarget
    const originalText = button.innerHTML
    button.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.progressTarget.classList.remove("hidden")
    this.startProgressSimulation()
    
    const transcription = this.transcriptionTarget.value
    
    if (!transcription) {
      alert("Please enter a transcription first")
      this.resetUI(originalText)
      return
    }
    
    try {
      const response = await fetch(this.element.dataset.summaryUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ transcription })
      })
      
      if (response.ok) {
        const data = await response.json()
        
        if (this.summaryTarget.querySelector("trix-editor")) {
          const trixEditor = this.summaryTarget.querySelector("trix-editor")
          trixEditor.editor.loadHTML(data.summary)
        } else {
          this.summaryTarget.value = data.summary
        }
        this.completeProgress()
      } else {
        const error = await response.json()
        alert(`Error: ${error.error || "Failed to generate summary"}`)
      }
    } catch (error) {
      console.error("Error generating summary:", error)
      alert("An error occurred while generating the summary")
    } finally {
      setTimeout(() => this.resetUI(originalText), 500)
    }
  }

  startProgressSimulation() {
    this.progressInterval = setInterval(() => {
      if (this.progress < 90) {
        this.progress += Math.random() * 15
        this.updateProgressBar()
      }
    }, 500)
  }

  completeProgress() {
    clearInterval(this.progressInterval)
    this.progress = 100
    this.updateProgressBar()
  }

  updateProgressBar() {
    this.progressTarget.style.width = `${Math.min(this.progress, 100)}%`
  }

  resetUI(originalText) {
    clearInterval(this.progressInterval)
    this.progress = 0
    this.updateProgressBar()
    this.buttonTarget.disabled = false
    this.buttonTarget.innerHTML = originalText
    this.spinnerTarget.classList.add("hidden")
    this.progressTarget.classList.add("hidden")
  }
}