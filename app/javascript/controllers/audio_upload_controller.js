import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "audioInput", "audioPreview", "transcriptionField", "summaryField", 
                    "processButton", "transcribeButton", "loadingIndicator", "progressBar", "errorMessage"]
  
  connect() {
    this.isProcessing = false
  }
  
  previewAudio() {
    const file = this.audioInputTarget.files[0]
    if (!file) return
    
    // Create audio preview
    const audioURL = URL.createObjectURL(file)
    this.audioPreviewTarget.src = audioURL
    this.audioPreviewTarget.classList.remove("hidden")
    
    // Enable processing buttons
    this.processButtonTarget.disabled = false
    this.transcribeButtonTarget.disabled = false
  }
  
  async processAudio(event) {
    event.preventDefault()
    
    if (this.isProcessing) return
    this.isProcessing = true
    
    // Show loading state
    this.loadingIndicatorTarget.classList.remove("hidden")
    this.errorMessageTarget.classList.add("hidden")
    this.processButtonTarget.disabled = true
    this.transcribeButtonTarget.disabled = true
    
    // Start progress simulation
    this.startProgressSimulation()
    
    const formData = new FormData()
    formData.append('audio_file', this.audioInputTarget.files[0])
    formData.append('title', this.formTarget.querySelector('#note_title').value)
    formData.append('generate_summary', 'true')
    
    try {
      const response = await fetch('/notes/process_audio', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        
        // Update form fields with transcription and summary
        if (this.transcriptionFieldTarget.querySelector("trix-editor")) {
          const trixEditor = this.transcriptionFieldTarget.querySelector("trix-editor")
          trixEditor.editor.loadHTML(data.transcription)
        } else {
          this.transcriptionFieldTarget.value = data.transcription
        }
        
        if (this.summaryFieldTarget.querySelector("trix-editor")) {
          const trixEditor = this.summaryFieldTarget.querySelector("trix-editor")
          trixEditor.editor.loadHTML(data.summary)
        } else {
          this.summaryFieldTarget.value = data.summary
        }
        
        this.completeProgress()
        // Removed auto-submission code here
      } else {
        const error = await response.json()
        this.showError(error.errors ? error.errors.join(", ") : "Failed to process audio")
      }
    } catch (error) {
      console.error("Error processing audio:", error)
      this.showError("An error occurred while processing the audio")
    } finally {
      this.isProcessing = false
      this.loadingIndicatorTarget.classList.add("hidden")
      this.processButtonTarget.disabled = false
      this.transcribeButtonTarget.disabled = false
    }
}

async transcribeOnly(event) {
    event.preventDefault()
    
    if (this.isProcessing) return
    this.isProcessing = true
    
    // Show loading state
    this.loadingIndicatorTarget.classList.remove("hidden")
    this.errorMessageTarget.classList.add("hidden")
    this.processButtonTarget.disabled = true
    this.transcribeButtonTarget.disabled = true
    
    // Start progress simulation
    this.startProgressSimulation()
    
    const formData = new FormData()
    formData.append('audio_file', this.audioInputTarget.files[0])
    formData.append('title', this.formTarget.querySelector('#note_title').value)
    formData.append('generate_summary', 'false')
    
    try {
      const response = await fetch('/notes/process_audio', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        
        // Update form field with transcription
        if (this.transcriptionFieldTarget.querySelector("trix-editor")) {
          const trixEditor = this.transcriptionFieldTarget.querySelector("trix-editor")
          trixEditor.editor.loadHTML(data.transcription)
        } else {
          this.transcriptionFieldTarget.value = data.transcription
        }
        
        this.completeProgress()
        // Removed auto-submission code here
      } else {
        const error = await response.json()
        this.showError(error.errors ? error.errors.join(", ") : "Failed to transcribe audio")
      }
    } catch (error) {
      console.error("Error transcribing audio:", error)
      this.showError("An error occurred while transcribing the audio")
    } finally {
      this.isProcessing = false
      this.loadingIndicatorTarget.classList.add("hidden")
      this.processButtonTarget.disabled = false
      this.transcribeButtonTarget.disabled = false
    }
}
  
  startProgressSimulation() {
    this.progressBarTarget.style.width = "0%"
    this.progressBarTarget.classList.remove("hidden")
    
    let progress = 0
    this.progressInterval = setInterval(() => {
      // Simulate progress that slows down as it approaches 90%
      if (progress < 90) {
        progress += (90 - progress) / 50
        this.progressBarTarget.style.width = `${progress}%`
      }
    }, 300)
  }
  
  completeProgress() {
    clearInterval(this.progressInterval)
    this.progressBarTarget.style.width = "100%"
    
    setTimeout(() => {
      this.progressBarTarget.classList.add("hidden")
    }, 500)
  }
  
  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
    clearInterval(this.progressInterval)
    this.progressBarTarget.classList.add("hidden")
  }
}
