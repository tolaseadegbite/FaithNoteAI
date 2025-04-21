class AudioProcessingService
  def initialize(params)
    @audio_file = params[:audio_file]
    @generate_summary = params[:generate_summary] == 'true'
  end

  def process
    # Validate presence of audio file
    if @audio_file.nil?
      return { error: "No audio file uploaded" }
    end

    # Generate a unique job ID
    job_id = SecureRandom.uuid

    # Create a temporary file path
    temp_file_path = Rails.root.join('tmp', "audio_upload_#{job_id}#{File.extname(@audio_file.original_filename)}")

    # Save the uploaded file
    begin
      File.open(temp_file_path, 'wb') do |file|
        file.write(@audio_file.read)
      end
    rescue => e
      Rails.logger.error("Failed to save uploaded audio file: #{e.message}")
      return { error: "Failed to process uploaded file" }
    end

    # Log the job initiation
    Rails.logger.info("Starting transcription job #{job_id} for file #{@audio_file.original_filename}")

    # Enqueue the background job
    InitiateAssemblyAiTranscriptionJob.perform_later(job_id, temp_file_path.to_s, @generate_summary)

    # Return the job ID on success
    { job_id: job_id }
  end
end