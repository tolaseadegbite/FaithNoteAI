import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "audioInput", "audioPreview", "transcriptionField", "summaryField",
                    "processButton", "transcribeButton", "loadingIndicator", "progressBar", "errorMessage"]

  connect() {
    this.isProcessing = false
    this.pollingInterval = null // Initialize polling interval
    this.progressInterval = null // Initialize progress interval
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

        // Start polling for transcription completion
        this.pollTranscriptionStatus(data.job_id, true) // Pass generateSummary flag
      } else {
        // Handle error response
        const error = await response.json()
        this.showError(error.errors ? error.errors.join(", ") : "Failed to process audio")
        this.resetUIOnError() // Reset UI on error
      }
    } catch (error) {
      console.error("Error processing audio:", error)
      this.showError("An error occurred while processing the audio")
      this.resetUIOnError() // Reset UI on error
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

        // Start polling for transcription completion
        this.pollTranscriptionStatus(data.job_id, false) // Pass generateSummary flag
      } else {
        // Handle error response
        const error = await response.json()
        this.showError(error.errors ? error.errors.join(", ") : "Failed to transcribe audio")
        this.resetUIOnError() // Reset UI on error
      }
    } catch (error) {
      console.error("Error transcribing audio:", error)
      this.showError("An error occurred while transcribing the audio")
      this.resetUIOnError() // Reset UI on error
    }
  }

  // Updated pollTranscriptionStatus
  async pollTranscriptionStatus(jobId, generateSummary) {
    // Clear any existing interval before starting a new one
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }

    this.pollingInterval = setInterval(async () => {
      try {
        // Pass generateSummary to the status check endpoint
        const response = await fetch(`/notes/check_transcription_status?job_id=${jobId}&generate_summary=${generateSummary}`)
        if (!response.ok) {
          // Stop polling on non-OK responses (like 404 Not Found if job_id is invalid)
          clearInterval(this.pollingInterval)
          this.showError(`Polling failed: Server responded with status ${response.status}`)
          this.resetUIOnError()
          throw new Error(`Polling failed with status: ${response.status}`) // Throw to exit async function
        }

        const data = await response.json()

        console.log("Polling status:", data.status) // Log status for debugging

        // Update progress based on status (optional refinement)
        // this.updateProgressBasedOnStatus(data.status);

        if (data.status === 'completed' || data.status === 'completed_with_summary' || data.status === 'completed_summary_failed') {
          clearInterval(this.pollingInterval)
          this.handleTranscriptionComplete(data)
        } else if (data.status === 'error' || data.status === 'error_generating_summary') {
          clearInterval(this.pollingInterval)
          this.showError(data.message || "Processing failed.")
          this.resetUIOnError() // Ensure UI resets on error
        } else {
          // Continue polling for 'starting', 'processing', 'generating_summary'
          // Update simulated progress if desired
          this.updateSimulatedProgress()
        }
      } catch (error) {
        // Catch network errors or errors from response handling
        console.error("Error during polling:", error)
        clearInterval(this.pollingInterval) // Stop polling on error
        this.showError("An error occurred while checking status.")
        this.resetUIOnError()
      }
    }, 3000) // Poll every 3 seconds (adjust as needed)
  }

  // Add this method to handle completed transcription
  handleTranscriptionComplete(data) {
    // Format the transcription with proper paragraph breaks
    const formattedTranscription = this.formatTranscriptionWithBreaks(data.transcription)

    // Update form field with transcription
    if (this.hasTranscriptionFieldTarget && this.transcriptionFieldTarget.querySelector("trix-editor")) {
      const trixEditor = this.transcriptionFieldTarget.querySelector("trix-editor")
      trixEditor.editor.loadHTML(formattedTranscription)
    } else if (this.hasTranscriptionFieldTarget) {
      this.transcriptionFieldTarget.value = formattedTranscription
    }

    // Handle summary if present
    if (data.summary && this.hasSummaryFieldTarget) {
      if (this.summaryFieldTarget.querySelector("trix-editor")) {
        const trixEditor = this.summaryFieldTarget.querySelector("trix-editor")
        trixEditor.editor.loadHTML(data.summary)
      } else {
        this.summaryFieldTarget.value = data.summary
      }
    }

    // Handle specific error case for summary generation
    if (data.status === 'completed_summary_failed') {
        this.showError(data.message || "Transcription completed, but summary generation failed.")
        // Don't fully reset UI, just show the error alongside results
        this.completeProgress() // Still complete progress bar
        this.isProcessing = false
        this.loadingIndicatorTarget.classList.add("hidden")
        this.processButtonTarget.disabled = false
        this.transcribeButtonTarget.disabled = false
    } else {
        // Normal completion
        this.completeProgress()
        this.isProcessing = false
        this.loadingIndicatorTarget.classList.add("hidden")
        this.processButtonTarget.disabled = false
        this.transcribeButtonTarget.disabled = false
    }
  }

  // Add a new method to format transcription with breaks
  formatTranscriptionWithBreaks(text) {
    if (!text) return '';

    // Replace speaker labels followed by a colon and optional space with paragraph breaks
    // This handles "Speaker A: Text" and puts each on a new line (wrapped in <p>)
    // It also handles the [END] marker by putting it in its own paragraph.
    const htmlText = text
      .replace(/(\[END\])/g, '</p><p>$1</p><p>') // Handle [END] marker
      .replace(/(Speaker [A-Z]:\s*)/g, '</p><p>$1') // Add break before speaker labels
      .trim();

    // Wrap the entire thing in <p> tags if it doesn't already start/end with them
    // and clean up potential empty paragraphs
    let wrappedText = htmlText;
    if (!wrappedText.startsWith('<p>')) {
        wrappedText = '<p>' + wrappedText;
    }
    if (!wrappedText.endsWith('</p>')) {
        wrappedText = wrappedText + '</p>';
    }

    // Remove empty paragraphs that might result from replacements
    return wrappedText.replace(/<p><\/p>/g, '');
  }

  startProgressSimulation() {
    // Clear any existing interval
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }
    this.progressBarTarget.style.width = "0%"
    this.progressBarTarget.classList.remove("hidden")

    let progress = 0
    this.progressInterval = setInterval(() => {
      // Simulate progress that slows down as it approaches 90%
      if (progress < 90) {
        // Adjust the divisor for speed (smaller = faster initial progress)
        progress += (90 - progress) / 30
        this.progressBarTarget.style.width = `${progress}%`
      } else {
        // Stop the interval once it hits 90% to prevent it from running indefinitely
        // if the process takes longer than the simulation.
        // It will jump to 100% in completeProgress or hide on error.
         clearInterval(this.progressInterval)
      }
    }, 300) // Update interval (e.g., 300ms)
  }

  // New method to update simulated progress without resetting it
  updateSimulatedProgress() {
    // This method is called during polling when status is still processing.
    // We check if the progress interval is still running. If not (e.g., it reached 90%),
    // we don't restart it. If it is running, we let it continue.
    // We could add more sophisticated logic here if needed, e.g., slightly bumping
    // the progress bar based on polling updates, but the simple simulation is often sufficient.
    if (!this.progressInterval) {
       // Optional: If the interval stopped (hit 90%), maybe nudge it slightly?
       // let currentWidth = parseFloat(this.progressBarTarget.style.width);
       // if (currentWidth < 95) {
       //   this.progressBarTarget.style.width = `${currentWidth + 1}%`;
       // }
    }
  }


  completeProgress() {
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
      this.progressInterval = null // Clear the interval ID
    }
    this.progressBarTarget.style.width = "100%"

    // Give a short time for the user to see 100% before hiding
    setTimeout(() => {
      this.progressBarTarget.classList.add("hidden")
      this.progressBarTarget.style.width = "0%" // Reset for next time
    }, 500)
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
    // Stop simulation and hide progress bar on error
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
      this.progressInterval = null
    }
    this.progressBarTarget.classList.add("hidden")
    this.progressBarTarget.style.width = "0%" // Reset progress bar
    // Hide loading indicator
    this.loadingIndicatorTarget.classList.add("hidden")
  }

  // Added helper to reset UI state, especially on errors during polling
  resetUIOnError() {
    this.isProcessing = false
    this.loadingIndicatorTarget.classList.add("hidden")
    // Re-enable buttons only if an audio file is still selected
    if (this.audioInputTarget.files.length > 0) {
        this.processButtonTarget.disabled = false
        this.transcribeButtonTarget.disabled = false
    } else {
        this.processButtonTarget.disabled = true
        this.transcribeButtonTarget.disabled = true
    }
    // Ensure intervals are cleared
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
      this.pollingInterval = null
    }
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
      this.progressInterval = null
    }
    // Hide progress bar just in case
    this.progressBarTarget.classList.add("hidden")
    this.progressBarTarget.style.width = "0%"
  }

  // Clear intervals when the controller disconnects
  disconnect() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }
  }
}
