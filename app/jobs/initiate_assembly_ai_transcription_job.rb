require 'fileutils'

class InitiateAssemblyAiTranscriptionJob < ApplicationJob
  # Change this line:
  queue_as :transcription # Use the dedicated transcription queue

  # Error class for job-specific issues
  class JobError < StandardError; end

  # Configure retries for transient errors (ApiError is now raised for network/API issues)
  retry_on AssemblyAiDirectTranscriptionService::ApiError, attempts: 3, wait: :exponentially_longer
  # Consider if you still need retry_on StandardError or if ApiError covers most transient cases

  # unique_job_id: A unique identifier for this whole transcription task (e.g., SecureRandom.uuid)
  # file_path: Path to the *temporary* audio file to process
  # generate_summary: Boolean indicating if a summary should be generated after transcription
  def perform(unique_job_id, file_path, generate_summary)
    Rails.logger.info("[Job:#{unique_job_id}] Initiating AssemblyAI transcription for file: #{file_path}")

    # Store initial status in cache
    cache_key_status = "transcription_status_#{unique_job_id}"
    cache_key_result = "transcription_result_#{unique_job_id}"
    cache_key_summary = "transcription_summary_#{unique_job_id}"
    Rails.cache.write(cache_key_status, { status: 'starting', generate_summary: generate_summary }, expires_in: 24.hours)

    # Ensure file exists before proceeding
    unless File.exist?(file_path)
      error_message = "Audio file not found at #{file_path}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      Rails.cache.write(cache_key_status, { status: 'error', message: error_message }, expires_in: 24.hours)
      # Optionally clean up the non-existent file path reference if needed
      return # Stop processing
    end

    begin
      service = AssemblyAiDirectTranscriptionService.new
      # The service now returns a Hash
      transcript_data = service.initiate_transcription(file_path)
      # Extract the ID from the Hash
      assembly_ai_id = transcript_data['id']

      # Ensure we got an ID
      unless assembly_ai_id
        error_message = "AssemblyAI initiation did not return a transcript ID."
        Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
        Rails.cache.write(cache_key_status, { status: 'error', message: error_message }, expires_in: 24.hours)
        return # Stop processing
      end

      # Store the AssemblyAI transcript ID and update status
      Rails.cache.write(cache_key_status, {
        status: 'processing',
        assembly_ai_id: assembly_ai_id, # Use the extracted ID
        generate_summary: generate_summary
      }, expires_in: 24.hours)

      Rails.logger.info("[Job:#{unique_job_id}] AssemblyAI job submitted. ID: #{assembly_ai_id}. Scheduling status check.") # Use the extracted ID

      # Schedule the first status check job
      CheckAssemblyAiStatusJob.set(wait: AssemblyAiDirectTranscriptionService::POLL_INTERVAL.seconds).perform_later(unique_job_id, assembly_ai_id, 0) # Use the extracted ID

    # Catch the specific errors raised by the refactored service
    rescue AssemblyAiDirectTranscriptionService::ApiError, AssemblyAiDirectTranscriptionService::TranscriptionError => e
      error_message = "AssemblyAI Service Error during initiation: #{e.message}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      Rails.cache.write(cache_key_status, { status: 'error', message: error_message }, expires_in: 24.hours)
      # No re-raise needed, error is cached, job won't retry these specific errors unless ApiError is transient

    rescue StandardError => e
      # Catch other unexpected errors during job execution
      error_message = "Unexpected error in InitiateAssemblyAiTranscriptionJob: #{e.class} - #{e.message}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      Rails.logger.error(e.backtrace.join("\n"))
      Rails.cache.write(cache_key_status, { status: 'error', message: "Job failed: #{e.class}" }, expires_in: 24.hours)
      # Re-raise to allow ActiveJob retry mechanism for non-API errors
      raise e
    ensure
      # Clean up the temporary audio file after initiating transcription (or if it failed)
      begin
        FileUtils.rm_f(file_path)
        Rails.logger.info("[Job:#{unique_job_id}] Cleaned up temporary audio file: #{file_path}")
      rescue => e
        Rails.logger.error("[Job:#{unique_job_id}] Failed to clean up temporary audio file #{file_path}: #{e.message}")
      end
    end
  end
end
