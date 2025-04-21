require 'fileutils'
require 'httparty' # Add HTTParty
require 'json'     # For parsing JSON

# Service to transcribe a full audio file using the AssemblyAI API (direct method)
class AssemblyAiDirectTranscriptionService
  include HTTParty # Include HTTParty
  base_uri 'https://api.assemblyai.com/v2' # Set base URI

  # Custom error class for AssemblyAI specific issues
  class TranscriptionError < StandardError; end
  class ApiError < StandardError; end # For SDK/API specific errors

  # Define possible statuses from AssemblyAI API (as strings)
  STATUS_QUEUED = "queued"
  STATUS_PROCESSING = "processing"
  STATUS_COMPLETED = "completed"
  STATUS_ERROR = "error"

  # Polling configuration (adjust as needed)
  POLL_INTERVAL = 10 # seconds
  MAX_POLL_ATTEMPTS = 60 # e.g., 60 attempts * 10 seconds = 10 minutes timeout

  def initialize
    @api_key = Rails.application.credentials.dig(:assembly_ai, :api_key)
    unless @api_key
      Rails.logger.error("AssemblyAI API key not found in credentials!")
      raise "Missing AssemblyAI API Key"
    end
    # Remove SDK client initialization:
    # @client = AssemblyAI::Client.new(api_key: @api_key)
    @headers = {
      "Authorization" => @api_key,
      "Content-Type" => "application/json" # Default content type for most requests
    }
  end

  # Uploads the audio file and initiates the transcription process.
  # Returns the initial transcript data (Hash) containing the ID and status.
  # audio_file_path: Path to the audio file to transcribe.
  def initiate_transcription(audio_file_path)
    unless File.exist?(audio_file_path)
      Rails.logger.error("Audio file not found at path: #{audio_file_path}")
      raise TranscriptionError, "Audio file not found: #{audio_file_path}"
    end

    file_basename = File.basename(audio_file_path)
    Rails.logger.info("Initiating AssemblyAI transcription for: #{file_basename}")

    begin
      # 1. Upload the local audio file to AssemblyAI /v2/upload endpoint
      #    This endpoint expects the raw file data, not JSON.
      upload_headers = { "Authorization" => @api_key } # No Content-Type needed usually
      upload_response = self.class.post('/upload',
                                        headers: upload_headers,
                                        body: File.read(audio_file_path),
                                        # Let HTTParty handle transfer encoding based on body
                                        # transfer_encoding: 'chunked' # May be needed for large files
                                        timeout: 300 # Increase timeout for uploads
                                       )

      unless upload_response.success?
        error_message = "AssemblyAI file upload failed for #{file_basename}. Status: #{upload_response.code}. Body: #{upload_response.body}"
        Rails.logger.error(error_message)
        raise ApiError, "AssemblyAI Upload Error: #{upload_response.code}"
      end

      upload_url = upload_response.parsed_response['upload_url']
      Rails.logger.info("AssemblyAI: Successfully uploaded file, upload_url: #{upload_url}")

      # 2. Submit the transcription job using the upload_url
      transcript_params = {
        audio_url: upload_url,
        speaker_labels: true,
        speech_model: "nano"
        # language_code: 'en_us'
      }
      submit_response = self.class.post('/transcript',
                                        headers: @headers, # Uses JSON content type
                                        body: transcript_params.to_json,
                                        timeout: 60)

      unless submit_response.success?
        error_message = "AssemblyAI job submission failed for #{file_basename}. Status: #{submit_response.code}. Body: #{submit_response.body}"
        Rails.logger.error(error_message)
        raise ApiError, "AssemblyAI Submission Error: #{submit_response.code}"
      end

      transcript_data = submit_response.parsed_response
      Rails.logger.info("AssemblyAI: Transcription job submitted. ID: #{transcript_data['id']}, Status: #{transcript_data['status']}, Model: #{transcript_params[:speech_model]}")

      # Check for immediate errors during submission
      if transcript_data['status'] == STATUS_ERROR
        error_message = "AssemblyAI job submission failed immediately. Error: #{transcript_data['error']}"
        Rails.logger.error(error_message)
        raise TranscriptionError, error_message
      end

      # Return the transcript data hash (contains ID and initial status)
      # Convert keys to symbols if preferred downstream
      # transcript_data.deep_symbolize_keys!
      transcript_data # Return the raw hash

    rescue HTTParty::Error, SocketError, Net::ReadTimeout, Net::OpenTimeout => e
      # Catch network/HTTP level errors
      error_message = "Network/HTTP Error during AssemblyAI initiation for #{file_basename}: #{e.class} - #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))
      raise ApiError, "Network error communicating with AssemblyAI: #{e.message}"
    rescue JSON::ParserError => e
      error_message = "JSON Parsing Error during AssemblyAI initiation for #{file_basename}: #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error("Response body causing error: #{e.response&.body}") # Log body if available
      raise ApiError, "Error parsing AssemblyAI response"
    rescue StandardError => e
      # Catch other unexpected errors
      error_message = "Unexpected error during AssemblyAI initiation for #{file_basename}: #{e.class} - #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))
      # Re-raise as TranscriptionError or ApiError depending on context if possible,
      # otherwise let the original error propagate or raise a generic one.
      raise TranscriptionError, "Unexpected error during transcription initiation: #{e.message}"
    end
  end

  # Fetches the current status and result of a transcription job.
  # transcript_id: The ID of the AssemblyAI transcript job.
  # Returns the transcript data (Hash) from AssemblyAI.
  def get_transcription_result(transcript_id)
    Rails.logger.debug("AssemblyAI: Checking status for transcript ID: #{transcript_id}")
    begin
      response = self.class.get("/transcript/#{transcript_id}", headers: @headers, timeout: 60)

      unless response.success?
        # Handle specific errors like 404 Not Found differently if needed
        if response.code == 404
           error_message = "AssemblyAI transcript not found for ID #{transcript_id}."
           Rails.logger.error(error_message)
           raise ApiError, error_message # Or return a specific status/nil
        else
          error_message = "AssemblyAI API Error fetching status for ID #{transcript_id}. Status: #{response.code}. Body: #{response.body}"
          Rails.logger.error(error_message)
          raise ApiError, "AssemblyAI Status Check Error: #{response.code}"
        end
      end

      transcript_data = response.parsed_response
      # transcript_data.deep_symbolize_keys!
      transcript_data # Return the raw hash

    rescue HTTParty::Error, SocketError, Net::ReadTimeout, Net::OpenTimeout => e
      error_message = "Network/HTTP Error fetching AssemblyAI status for ID #{transcript_id}: #{e.class} - #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))
      raise ApiError, "Network error checking AssemblyAI status: #{e.message}"
    rescue JSON::ParserError => e
      error_message = "JSON Parsing Error fetching AssemblyAI status for ID #{transcript_id}: #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error("Response body causing error: #{e.response&.body}")
      raise ApiError, "Error parsing AssemblyAI status response"
    rescue StandardError => e
      error_message = "Unexpected error fetching AssemblyAI status for ID #{transcript_id}: #{e.class} - #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))
      raise TranscriptionError, "Unexpected error during status check: #{e.message}"
    end
  end

  # DEPRECATED in favor of background job polling - kept for reference or direct use cases
  # Note: This would need updating to use the new get_transcription_result and string statuses
  def poll_for_completion(transcript_id)
     # ... (Needs refactoring if used) ...
     raise NotImplementedError, "poll_for_completion needs refactoring for direct API calls"
  end

  # Helper to format the transcript text, potentially handling speaker labels
  # transcript_data: The completed transcript data Hash from the API.
  def format_transcript_text(transcript_data)
    # Log the transcript data structure to help with debugging
    Rails.logger.debug("AssemblyAI: Formatting transcript data: #{transcript_data.keys}")
    
    # Check if the transcript has text
    if transcript_data['text'].present?
      # Use the full text from the transcript
      text = transcript_data['text']
      
      # If there are speaker labels (utterances), format them nicely
      if transcript_data['utterances'].present? && transcript_data['utterances'].any?
        Rails.logger.debug("AssemblyAI: Found #{transcript_data['utterances'].size} utterances with speaker labels")
        
        # Format with speaker labels
        formatted_text = transcript_data['utterances'].map do |utterance|
          speaker = utterance['speaker'] || 'Unknown'
          utterance_text = utterance['text'] || ''
          "Speaker #{speaker}: #{utterance_text}"
        end.join("\n\n")
        
        return formatted_text
      end
      
      # Return the plain text if no speaker labels
      return text
    elsif transcript_data['status'] == STATUS_COMPLETED
      # If status is completed but no text, log a warning
      Rails.logger.warn("AssemblyAI: Transcript marked as completed but no text found. ID: #{transcript_data['id']}")
      return "[No text found in transcript]"
    else
      # If not completed, return a message indicating the status
      return "[Transcript status: #{transcript_data['status']}]"
    end
  end

  # Get a list of recent transcriptions
  # limit: Maximum number of transcriptions to return
  def get_recent_transcriptions(limit = 5)
    Rails.logger.debug("AssemblyAI: Retrieving #{limit} recent transcriptions")
    
    begin
      response = self.class.get("/transcript", 
                               headers: @headers, 
                               query: { limit: limit },
                               timeout: 60)

      unless response.success?
        error_message = "AssemblyAI API Error fetching recent transcriptions. Status: #{response.code}. Body: #{response.body}"
        Rails.logger.error(error_message)
        raise ApiError, "AssemblyAI List Error: #{response.code}"
      end

      transcripts = response.parsed_response['transcripts'] || []
      Rails.logger.info("AssemblyAI: Retrieved #{transcripts.size} recent transcriptions")
      transcripts
      
    rescue HTTParty::Error, SocketError, Net::ReadTimeout, Net::OpenTimeout => e
      error_message = "Network/HTTP Error fetching AssemblyAI transcriptions: #{e.class} - #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))
      raise ApiError, "Network error listing AssemblyAI transcriptions: #{e.message}"
    end
  end
end