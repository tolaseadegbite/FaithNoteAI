require "net/http"
require "json"
require "redcarpet"

class GeminiTranscriptionService
    # BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-exp-03-25:generateContent"
      BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent"
    # BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  
  def initialize
    @api_key = Rails.application.credentials.dig(:gemini, :api_key)
    
    # Initialize Redcarpet markdown renderer
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
      autolink: true, 
      tables: true, 
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      superscript: true,
      underline: true,
      quote: true)
  end
  
  def transcribe(audio_file)
    begin
      # Convert audio file to base64
      audio_content = Base64.strict_encode64(audio_file.read)
      audio_file.rewind # Rewind the file pointer for potential future use
      
      # Prepare the request payload
      payload = {
        contents: [
          {
            parts: [
                {
                  text: "You are an expert transcriptionist specializing in spoken audio content. Your goal is to accurately transcribe the provided audio and speaker identification, following a specific format. Please adhere to the following guidelines:

                  1. Basic Transcription and Formatting:
                  * Transcribe all spoken words verbatim, removing filler words (um, uh, like, you know, etc.).
                  * Do not use any markdown formatting like bolding or italics.
                  * Only use characters from the English alphabet unless you genuinely believe foreign characters are correct.
                  * Spell every word correctly, using the context of the audio to help with potentially ambiguous words (e.g., names, specific terminology).
                  * Each individual caption (speaker turn) should be quite short, a few short sentences at most.
                  * Signify the end of the audio with [END].
                  
                  3. Speaker Identification:
                  * Identify each distinct speaker in the audio. Label them sequentially starting with 'Speaker A', then 'Speaker B', 'Speaker C', and so on (e.g., Speaker A: Hello there.). Use a new speaker label for each new speaker identified.
                  
                  4. Non-Speech Audio:
                  * If a song is being sung and you are **sure** of the name of the song, include it like this: `[Singing: Song Title]` (e.g., `[Singing: Amazing Grace]`)
                  * If there is music playing and you are **not sure** of the song name, signify it like this: `[MUSIC]`
                  * If there is a sound effect, try to identify the sound: `[Bell ringing]`
                  * If there is a significant period of silence, you can indicate it as: `[SILENCE]`
                  
                  5. Specific Instructions:
                  * Given that the audio content may be Christian-related talks such as sermons or sessions, pay close attention to theological terms and potential biblical references. Ensure accuracy in these areas.
                  * Do your best to transcribe accurately regardless of the audio quality. If parts are unclear, indicate them with [inaudible].
                  
                  6. Contextual Information:
                  * Possible Type of Audio: Might be a sermon or workshop session.
                  * Possible Language: The audio may be in English or possibly in a different language.
                  * Possible Theme: The audio may be about Christianity, theology, or other Christian-related topics.
                  
                  7. Output Format:
                  * The output should be in plain text format.
                  * Each speaker's caption should be on a new line, starting with the speaker label.
                  
                  8. Timestamps:
                  * **Crucially, do NOT include any timestamps in the output.**
                  * **There should be no timestamps present at the beginning of any speaker's turn or any other part of the transcription.**
                  * **The desired output is purely the transcribed text with speaker labels.**
                  "
                  },
              {
                inline_data: {
                  mime_type: audio_file.content_type || "audio/mpeg",
                  data: audio_content
                }
              }
            ]
          }
        ],
        generationConfig: {
          temperature: 0.1,
          topP: 0.8,
          topK: 40
        }
      }
      
      # Make the API request using Net::HTTP like in GeminiService
      uri = URI("#{BASE_URL}?key=#{@api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 1200 # Increase timeout for large audio files
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = @api_key # Add API key in header
      request.body = payload.to_json
      
      Rails.logger.info("Making transcription request to Gemini API")
      
      response = http.request(request)
      result = JSON.parse(response.body)
      
      if response.code == "200" && result["candidates"] && !result["candidates"].empty?
        # Extract the transcription text from the response
        transcription = result["candidates"][0]["content"]["parts"][0]["text"]
        Rails.logger.info("Successfully received transcription from Gemini API")
        return transcription
      else
        Rails.logger.error("Gemini transcription error: #{result.inspect}")
        return nil
      end
    rescue => e
      Rails.logger.error("Gemini transcription error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return nil
    end
  end
end