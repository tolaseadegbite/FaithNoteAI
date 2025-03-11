import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "recordIcon", "stopIcon", "recordingIndicator", "timer", "tooltip"]
  
  connect() {
    this.isRecording = false
    this.recordingTime = 0
    this.timerInterval = null
    
    // Check if browser supports audio recording
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      console.error("Your browser doesn't support audio recording")
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
  
  toggleRecording() {
    if (this.isRecording) {
      this.stopRecording()
    } else {
      this.startRecording()
    }
  }
  
  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []
      
      this.mediaRecorder.addEventListener("dataavailable", (event) => {
        this.audioChunks.push(event.data)
      })
      
      this.mediaRecorder.addEventListener("stop", () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/wav' })
        this.processRecording(audioBlob)
      })
      
      this.mediaRecorder.start()
      this.isRecording = true
      
      // Update UI
      this.recordIconTarget.classList.add("hidden")
      this.stopIconTarget.classList.remove("hidden")
      this.recordingIndicatorTarget.classList.remove("hidden")
      this.timerTarget.classList.remove("hidden")
      this.tooltipTarget.classList.add("hidden")
      
      // Start timer
      this.recordingTime = 0
      this.updateTimer()
      this.timerInterval = setInterval(() => this.updateTimer(), 1000)
      
    } catch (error) {
      console.error("Error accessing microphone:", error)
      // Show error message to user
      this.showNotification("Could not access microphone", "error")
    }
  }
  
  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
      this.isRecording = false
      
      // Update UI
      this.recordIconTarget.classList.remove("hidden")
      this.stopIconTarget.classList.add("hidden")
      this.recordingIndicatorTarget.classList.add("hidden")
      this.timerTarget.classList.add("hidden")
      this.tooltipTarget.classList.remove("hidden")
      
      // Show processing indicator
      this.showNotification("Processing recording...", "info")
      
      // Stop timer
      clearInterval(this.timerInterval)
    }
  }
  
  updateTimer() {
    this.recordingTime += 1
    const minutes = Math.floor(this.recordingTime / 60).toString().padStart(2, '0')
    const seconds = (this.recordingTime % 60).toString().padStart(2, '0')
    this.timerTarget.textContent = `${minutes}:${seconds}`
  }
  
  async processRecording(audioBlob) {
    // Create a FormData object to send the audio file
    const formData = new FormData()
    formData.append('note[audio_file]', audioBlob, 'recording.wav')
    formData.append('note[title]', `Quick Recording ${new Date().toLocaleString()}`)
    
    try {
      // Send the audio to the server
      const response = await fetch('/notes/quick_record', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.showNotification("Recording saved successfully!", "success")
        // Redirect to the edit page for the new note
        window.location.href = `/notes/${data.id}/edit`
      } else {
        console.error("Error creating note with audio")
        this.showNotification("Failed to save recording", "error")
      }
    } catch (error) {
      console.error("Error processing recording:", error)
      this.showNotification("An error occurred", "error")
    }
  }
  
  showNotification(message, type) {
    // You could implement a toast notification system here
    // For now, we'll use a simple alert
    if (type === "error") {
      alert(`Error: ${message}`)
    } else {
      console.log(message)
    }
  }
  
  disconnect() {
    if (this.isRecording) {
      this.stopRecording()
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }
}