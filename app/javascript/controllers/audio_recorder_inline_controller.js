import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preRecording", "recording", "postRecording", "processing", "timer", "titleInput"]
  
  connect() {
    this.isRecording = false
    this.recordingTime = 0
    this.timerInterval = null
    this.audioChunks = []
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
        this.audioBlob = new Blob(this.audioChunks, { type: 'audio/wav' })
        this.showPostRecordingUI()
      })
      
      this.mediaRecorder.start()
      this.isRecording = true
      
      // Update UI
      this.preRecordingTarget.classList.add("hidden")
      this.recordingTarget.classList.remove("hidden")
      
      // Start timer
      this.recordingTime = 0
      this.updateTimer()
      this.timerInterval = setInterval(() => this.updateTimer(), 1000)
      
    } catch (error) {
      console.error("Error accessing microphone:", error)
      alert("Could not access microphone. Please check your browser permissions.")
    }
  }
  
  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
      this.isRecording = false
      
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
  
  showPostRecordingUI() {
    this.recordingTarget.classList.add("hidden")
    this.postRecordingTarget.classList.remove("hidden")
    
    // Set default title based on date/time
    const now = new Date()
    const formattedDate = now.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric' 
    })
    this.titleInputTarget.value = `Recording - ${formattedDate}`
  }
  
  discardRecording() {
    // Reset everything and go back to pre-recording state
    this.audioChunks = []
    this.audioBlob = null
    this.postRecordingTarget.classList.add("hidden")
    this.preRecordingTarget.classList.remove("hidden")
  }
  
  async saveRecording() {
    if (!this.audioBlob) {
      return
    }
    
    // Show processing UI
    this.postRecordingTarget.classList.add("hidden")
    this.processingTarget.classList.remove("hidden")
    
    // Create a FormData object to send the audio file
    const formData = new FormData()
    formData.append('note[audio_file]', this.audioBlob, 'recording.wav')
    formData.append('note[title]', this.titleInputTarget.value || 'Untitled Recording')
    
    try {
      // Send the audio to the server
      const response = await fetch('/notes', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        // Redirect to the edit page for the new note
        window.location.href = `/notes/${data.id}/edit`
      } else {
        console.error("Error creating note with audio")
        alert("Failed to save recording. Please try again.")
        this.processingTarget.classList.add("hidden")
        this.postRecordingTarget.classList.remove("hidden")
      }
    } catch (error) {
      console.error("Error processing recording:", error)
      alert("An error occurred while saving your recording.")
      this.processingTarget.classList.add("hidden")
      this.postRecordingTarget.classList.remove("hidden")
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