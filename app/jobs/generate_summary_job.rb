class GenerateSummaryJob < ApplicationJob
  queue_as :default # Keep on default unless Gemini needs rate limiting

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(unique_job_id, transcript_text)
    Rails.logger.info("[Job:#{unique_job_id}] Generating summary.")

    cache_key_status = "transcription_status_#{unique_job_id}"
    cache_key_summary = "transcription_summary_#{unique_job_id}"

    begin
      # Assuming GeminiService is still used for summaries
      summary_service = GeminiService.new
      summary = summary_service.generate_summary(transcript_text)

      if summary
        Rails.logger.info("[Job:#{unique_job_id}] Summary generated successfully.")
        Rails.cache.write(cache_key_summary, summary, expires_in: 24.hours)
        # Update final status to completed (including summary)
        current_status_data = Rails.cache.read(cache_key_status) || {}
        Rails.cache.write(cache_key_status, {
          status: 'completed_with_summary', # Final status
          assembly_ai_id: current_status_data[:assembly_ai_id],
          generate_summary: true
        }, expires_in: 24.hours)
      else
        Rails.logger.error("[Job:#{unique_job_id}] Summary generation returned nil.")
        # Update status to reflect completion but summary failure
         current_status_data = Rails.cache.read(cache_key_status) || {}
         Rails.cache.write(cache_key_status, {
           status: 'completed_summary_failed', # Indicate summary issue
           assembly_ai_id: current_status_data[:assembly_ai_id],
           generate_summary: true
         }, expires_in: 24.hours)
      end

    rescue StandardError => e
      error_message = "Error generating summary: #{e.class} - #{e.message}"
      Rails.logger.error("[Job:#{unique_job_id}] #{error_message}")
      Rails.logger.error(e.backtrace.join("\n"))
      # Update status to reflect summary generation error
      current_status_data = Rails.cache.read(cache_key_status) || {}
      Rails.cache.write(cache_key_status, {
        status: 'error_generating_summary', # Specific error status
        assembly_ai_id: current_status_data[:assembly_ai_id],
        generate_summary: true,
        message: "Summary generation failed: #{e.class}"
      }, expires_in: 24.hours)
      # Re-raise to potentially retry summary generation if desired
      raise e
    end
  end
end
