class CheckAssemblyAiStatusJob < ApplicationJob
  # Change this line:
  queue_as :transcription # Use the dedicated transcription queue

  # Configure retries for transient API/network errors during polling
  retry_on AssemblyAiDirectTranscriptionService::ApiError, attempts: 5, wait: :exponentially_longer

  # unique_job_id: The application's unique ID for the overall task
  # assembly_ai_id: The ID returned by AssemblyAI
  # attempt_count: Tracks polling attempts to prevent infinite loops
  def perform(unique_job_id, assembly_ai_id, attempt_count)
    Rails.logger.info("[Job:#{unique_job_id}] Checking AssemblyAI status for ID: #{assembly_ai_id} (Attempt: #{attempt_count + 1})")

    cache_key_status = "transcription_status_#{unique_job_id}"
    cache_key_result = "transcription_result_#{unique_job_id}"
    cache_key_summary = "transcription_summary_#{unique_job_id}"

    # Retrieve current status info (needed for generate_summary flag)
    current_status_data = Rails.cache.read(cache_key_status) || {}
    generate_summary = current_status_data.fetch(:generate_summary, false) # Default to false if not found

    begin
      service = AssemblyAiDirectTranscriptionService.new
      # Service now returns a Hash
      transcript_data = service.get_transcription_result(assembly_ai_id)
      # Access status using string key
      status = transcript_data['status']

      Rails.logger.debug("[Job:#{unique_job_id}] AssemblyAI Status: #{status}")

      case status
      # Use string constants from the service
      when AssemblyAiDirectTranscriptionService::STATUS_COMPLETED
        Rails.logger.info("[Job:#{unique_job_id}] Transcription completed successfully.")
        # Pass the Hash to the formatter
        final_text = service.format_transcript_text(transcript_data)
        # Store the final transcript
        Rails.cache.write(cache_key_result, final_text, expires_in: 24.hours)

        # Update status to completed
        Rails.cache.write(cache_key_status, {
          status: 'completed',
          assembly_ai_id: assembly_ai_id,
          generate_summary: generate_summary # Keep the flag
        }, expires_in: 24.hours)

        # --- Optional: Trigger Summary Generation ---
        if generate_summary
          Rails.logger.info("[Job:#{unique_job_id}] Triggering summary generation.")
          # Enqueue a new job specifically for summary generation
          GenerateSummaryJob.perform_later(unique_job_id, final_text)
          # Update status to indicate summary is pending
           Rails.cache.write(cache_key_status, {
             status: 'generating_summary', # New status
             assembly_ai_id: assembly_ai_id,
             generate_summary: true
           }, expires_in: 24.hours)
        end
        # --- End Optional Summary ---

      # Use string constant from the service
      when AssemblyAiDirectTranscriptionService::STATUS_ERROR
        # Access error message using string key
        error_message = "AssemblyAI transcription failed. Error: #{transcript_data['error']}"
        Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
        Rails.cache.write(cache_key_status, { status: 'error', message: error_message }, expires_in: 24.hours)
        # Optionally store the error in the result cache too
        Rails.cache.write(cache_key_result, "[Error: #{error_message}]", expires_in: 24.hours)

      # Use string constants from the service
      when AssemblyAiDirectTranscriptionService::STATUS_QUEUED, AssemblyAiDirectTranscriptionService::STATUS_PROCESSING
        # Check if max attempts reached
        if attempt_count + 1 >= AssemblyAiDirectTranscriptionService::MAX_POLL_ATTEMPTS
          timeout_message = "Polling timed out after #{attempt_count + 1} attempts."
          Rails.logger.error("[Job:#{unique_job_id}] #{timeout_message}")
          Rails.cache.write(cache_key_status, { status: 'error', message: timeout_message }, expires_in: 24.hours)
        else
          # Reschedule self to check again later
          Rails.logger.debug("[Job:#{unique_job_id}] Status is '#{status}'. Rescheduling check.")
          CheckAssemblyAiStatusJob.set(wait: AssemblyAiDirectTranscriptionService::POLL_INTERVAL.seconds).perform_later(unique_job_id, assembly_ai_id, attempt_count + 1)
        end
      else
        unknown_status_message = "AssemblyAI returned unknown status '#{status}'"
        Rails.logger.error("[Job:#{unique_job_id}] #{unknown_status_message}")
        Rails.cache.write(cache_key_status, { status: 'error', message: unknown_status_message }, expires_in: 24.hours)
      end

    # Catch specific service errors first
    rescue AssemblyAiDirectTranscriptionService::ApiError, AssemblyAiDirectTranscriptionService::TranscriptionError => e
      error_message = "AssemblyAI Service Error during status check: #{e.message}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      # ApiError might be retried by the retry_on directive above.
      # TranscriptionError is likely terminal for this check.
      # Cache the error. If it was an ApiError that exhausts retries, it will end up here too.
      Rails.cache.write(cache_key_status, { status: 'error', message: "Polling failed: #{e.message}" }, expires_in: 24.hours)
      # Don't re-raise TranscriptionError, let the job complete after caching.
      # ApiError will be re-raised by retry_on mechanism if retries remain.
      raise e if e.is_a?(AssemblyAiDirectTranscriptionService::ApiError)

    # Catch other unexpected errors AFTER specific service errors
    rescue StandardError => e
      # Catch other unexpected errors during job execution
      error_message = "Unexpected error in CheckAssemblyAiStatusJob: #{e.class} - #{e.message}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      Rails.logger.error(e.backtrace.join("\n"))
      # Cache a generic error status
      Rails.cache.write(cache_key_status, { status: 'error', message: "Job failed: #{e.class}" }, expires_in: 24.hours)
      # Re-raise to allow ActiveJob default retry mechanism ONLY for truly unexpected errors
      raise e
    end
  end
end
