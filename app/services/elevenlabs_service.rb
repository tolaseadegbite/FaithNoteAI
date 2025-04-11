require 'httparty'

class ElevenlabsService
  include HTTParty
  base_uri 'https://api.elevenlabs.io/v1'
  
  def initialize
    @api_key = Rails.application.credentials.elevenlabs[:api_key]
    @headers = {
      'xi-api-key' => @api_key,
      'Accept' => 'application/json'
    }
  end
  
  def transcribe(audio_file)
    # Create a multipart form with the audio file
    file_data = File.open(audio_file.tempfile.path, 'rb')
    
    response = self.class.post(
      '/speech-to-text',
      headers: @headers.except('Content-Type'),
      multipart: true,
      body: {
        model_id: 'scribe_v1',
        file: file_data,
        diarize: true,
        timestamps_granularity: 'word'
      }
    )
    
    if response.success?
      return response.parsed_response["text"]
    else
      Rails.logger.error("ElevenLabs API Error: #{response.code} - #{response.body}")
      return nil
    end
  ensure
    file_data.close if file_data
  end
end