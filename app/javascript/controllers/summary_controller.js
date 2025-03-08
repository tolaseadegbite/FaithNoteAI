import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["transcription", "summary", "button"]
  
  connect() {
    console.log("Summary controller connected")
  }
  
  async generate(event) {
    event.preventDefault()
    
    const button = this.buttonTarget
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = "Generating..."
    
    const transcription = this.transcriptionTarget.value
    
    if (!transcription) {
      alert("Please enter a transcription first")
      button.disabled = false
      button.innerHTML = originalText
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
        
        // For Action Text editor
        if (this.summaryTarget.querySelector("trix-editor")) {
          const trixEditor = this.summaryTarget.querySelector("trix-editor")
          // The summary is already HTML, so we can load it directly
          trixEditor.editor.loadHTML(data.summary)
        } else {
          // For regular textarea
          this.summaryTarget.value = data.summary
        }
      } else {
        const error = await response.json()
        alert(`Error: ${error.error || "Failed to generate summary"}`)
      }
    } catch (error) {
      console.error("Error generating summary:", error)
      alert("An error occurred while generating the summary")
    } finally {
      button.disabled = false
      button.innerHTML = originalText
    }
  }
}