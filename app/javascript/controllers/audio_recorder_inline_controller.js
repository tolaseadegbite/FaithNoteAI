import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "preRecording", "recording", "postRecording", "processing", 
    "audioPreview", "timer", "titleInput", "pauseResumeButton", 
    "pauseIcon", "resumeIcon", "pauseText", "resumeText"
  ]

  connect() {
    this.isRecording = false
    this.isPaused = false
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
      this.isPaused = false
      
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
    if (this.mediaRecorder && (this.isRecording || this.isPaused)) {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
      this.isRecording = false
      this.isPaused = false
      
      // Stop timer
      clearInterval(this.timerInterval)
    }
  }
  
  // New method to toggle pause/resume
  // Updated togglePause method
  togglePause() {
    if (!this.mediaRecorder) return
    
    if (this.isPaused) {
      // Resume recording
      this.mediaRecorder.resume()
      this.isPaused = false
      this.isRecording = true
      
      // Update UI - show pause elements, hide resume elements
      this.pauseIconTarget.classList.remove("hidden")
      this.resumeIconTarget.classList.add("hidden")
      this.pauseTextTarget.classList.remove("hidden")
      this.resumeTextTarget.classList.add("hidden")
      
      // Change button color back to yellow for pause
      this.pauseResumeButtonTarget.classList.remove("bg-green-500", "hover:bg-green-600")
      this.pauseResumeButtonTarget.classList.add("bg-yellow-500", "hover:bg-yellow-600")
      
      // Resume timer
      this.timerInterval = setInterval(() => this.updateTimer(), 1000)
    } else {
      // Pause recording
      this.mediaRecorder.pause()
      this.isPaused = true
      this.isRecording = false
      
      // Update UI - hide pause elements, show resume elements
      this.pauseIconTarget.classList.add("hidden")
      this.resumeIconTarget.classList.remove("hidden")
      this.pauseTextTarget.classList.add("hidden")
      this.resumeTextTarget.classList.remove("hidden")
      
      // Change button color to green for resume
      this.pauseResumeButtonTarget.classList.remove("bg-yellow-500", "hover:bg-yellow-600")
      this.pauseResumeButtonTarget.classList.add("bg-green-500", "hover:bg-green-600")
      
      // Pause timer
      clearInterval(this.timerInterval)
    }
  }

  updateTimer() {
    if (this.isRecording) {
      this.recordingTime++
      const minutes = Math.floor(this.recordingTime / 60).toString().padStart(2, '0')
      const seconds = (this.recordingTime % 60).toString().padStart(2, '0')
      this.timerTarget.textContent = `${minutes}:${seconds}`
    }
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
    this.audioBlob = null
    this.audioChunks = []
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
    if (this.isRecording || this.isPaused) {
      this.stopRecording()
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }
}