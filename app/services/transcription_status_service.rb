class TranscriptionStatusService
  def initialize(params)
    @job_id = params[:job_id]
    @generate_summary = params[:generate_summary] == "true"
  end

  def check
    # Log the incoming request
    Rails.logger.info("Checking transcription status for job_id: #{@job_id}, generate_summary: #{@generate_summary}")

    cache_key_status = "transcription_status_#{@job_id}"
    cache_key_result = "transcription_result_#{@job_id}"
    cache_key_summary = "transcription_summary_#{@job_id}"

    status_data = Rails.cache.read(cache_key_status)

    if status_data.nil?
      handle_cache_miss
    else
      handle_cache_hit(status_data)
    end
  end

  private

  def handle_cache_miss
    Rails.logger.warn("No status found in cache for job_id: #{@job_id}")
    # Attempt recovery logic
    begin
      service = AssemblyAiDirectTranscriptionService.new
      processed_transcripts_key = "processed_assembly_ai_transcripts"
      processed_transcript_ids = Rails.cache.fetch(processed_transcripts_key, expires_in: 24.hours) { [] }
      transcripts = service.get_recent_transcriptions(10)

      if transcripts.present?
        transcript_ids = transcripts.map { |t| t['id'] }
        Rails.logger.info("Available AssemblyAI transcripts: #{transcript_ids.join(', ')}")
        Rails.logger.info("Already processed transcripts: #{processed_transcript_ids.join(', ')}")
      end

      matching_transcript = find_unprocessed_transcript(transcripts, processed_transcript_ids)

      if matching_transcript
        process_recovered_transcript(matching_transcript, service, processed_transcripts_key, processed_transcript_ids)
      else
        Rails.logger.info("No unprocessed completed transcriptions found in AssemblyAI for recovery.")
        { body: { status: 'processing' }, status: :ok } # Default to processing if recovery fails
      end
    rescue => e
      Rails.logger.error("Error in recovery attempt for job_id #{@job_id}: #{e.message}")
      { body: { status: 'processing' }, status: :ok } # Default to processing on error
    end
  end

  def find_unprocessed_transcript(transcripts, processed_ids)
    return nil unless transcripts.present?
    transcripts.find do |t|
      t['status'] == AssemblyAiDirectTranscriptionService::STATUS_COMPLETED &&
      !processed_ids.include?(t['id'])
    end
  end

  def process_recovered_transcript(transcript, service, processed_key, processed_ids)
    transcript_id = transcript['id']
    Rails.logger.info("Found unprocessed completed transcription in AssemblyAI: #{transcript_id}")

    # Mark as processed
    processed_ids << transcript_id
    Rails.cache.write(processed_key, processed_ids, expires_in: 24.hours)

    # Fetch and format transcript
    transcript_data = service.get_transcription_result(transcript_id)
    Rails.logger.debug("AssemblyAI full transcript data keys: #{transcript_data.keys}")
    Rails.logger.debug("AssemblyAI transcript text sample: #{transcript_data['text']&.truncate(100)}")
    final_text = service.format_transcript_text(transcript_data)

    # Cache results
    cache_key_status = "transcription_status_#{@job_id}"
    cache_key_result = "transcription_result_#{@job_id}"
    cache_key_summary = "transcription_summary_#{@job_id}"

    Rails.cache.write(cache_key_status, {
      status: 'completed',
      assembly_ai_id: transcript_id,
      generate_summary: @generate_summary
    }, expires_in: 24.hours)
    Rails.cache.write(cache_key_result, final_text, expires_in: 24.hours)

    # Generate summary if requested
    summary = generate_summary_if_needed(final_text, transcript_id, cache_key_status, cache_key_summary)

    # Return response
    {
      body: {
        status: @generate_summary && summary ? 'summary_completed' : 'completed',
        transcription: final_text,
        summary: summary,
        recovered: true
      },
      status: :ok
    }
  end

  def generate_summary_if_needed(text, transcript_id, status_key, summary_key)
    return nil unless @generate_summary
    summary = nil
    Rails.logger.info("Generating summary for recovered transcription #{transcript_id}")
    begin
      summary = GeminiService.new.generate_summary(text)
      if summary.present?
        Rails.cache.write(summary_key, summary, expires_in: 24.hours)
        # Update status to reflect summary completion
        Rails.cache.write(status_key, {
          status: 'summary_completed', # Use a distinct status
          assembly_ai_id: transcript_id,
          generate_summary: true
        }, expires_in: 24.hours)
        Rails.logger.info("Summary generated and cached for recovered transcription #{transcript_id}")
      else
        Rails.logger.warn("Summary generation returned empty for recovered transcription #{transcript_id}")
      end
    rescue => e
      Rails.logger.error("Error generating summary during recovery for transcript #{transcript_id}: #{e.message}")
      # Optionally update status to indicate summary failure here if needed
    end
    summary
  end

  def handle_cache_hit(status_data)
    Rails.logger.info("Found status data for job_id #{@job_id}: #{status_data.inspect}")
    current_status = status_data[:status] || status_data['status'] # Handle symbol/string keys

    cache_key_result = "transcription_result_#{@job_id}"
    cache_key_summary = "transcription_summary_#{@job_id}"

    case current_status
    when 'completed', 'completed_with_summary', 'completed_summary_failed', 'summary_completed' # Added summary_completed
      transcription = Rails.cache.read(cache_key_result)
      summary = @generate_summary ? Rails.cache.read(cache_key_summary) : nil

      final_status = determine_final_status(current_status, summary)

      Rails.logger.info("Job #{@job_id}: Final status determined as '#{final_status}'.")
      {
        body: {
          status: final_status,
          transcription: transcription || "[Transcription not found in cache]",
          summary: summary,
          message: current_status == 'completed_summary_failed' ? status_data[:message] : nil
        },
        status: :ok
      }
    when 'generating_summary'
      Rails.logger.info("Job #{@job_id}: Status is 'generating_summary'.")
      { body: { status: 'generating_summary' }, status: :ok }
    when 'error'
      error_message = status_data[:message] || "Unknown error"
      Rails.logger.error("Job #{@job_id}: Transcription failed with error: #{error_message}")
      { body: { status: 'error', message: error_message }, status: :ok }
    when 'starting', 'processing'
      Rails.logger.info("Job #{@job_id}: Status is '#{current_status}'. Still processing.")
      { body: { status: 'processing' }, status: :ok }
    else
      Rails.logger.error("Job #{@job_id}: Encountered unexpected status '#{current_status}'.")
      { body: { status: 'error', message: "Unexpected status: #{current_status}" }, status: :ok }
    end
  end

  def determine_final_status(current_status, summary)
    if @generate_summary
      if current_status == 'completed_summary_failed'
        'completed_summary_failed'
      elsif summary.present? && ['completed_with_summary', 'summary_completed'].include?(current_status)
         # If summary exists and status indicates it should, use appropriate status
         current_status == 'summary_completed' ? 'summary_completed' : 'completed_with_summary'
      elsif summary.present? # Summary exists but status was just 'completed' (e.g., recovery)
        'summary_completed' # Or 'completed_with_summary' depending on desired final state name
      else # Summary requested but not present (or failed without specific status)
        'completed' # Fallback if summary failed silently or wasn't generated yet
      end
    else
      'completed' # No summary requested
    end
  end
end