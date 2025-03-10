require "net/http"
require "json"
require "redcarpet"

class GeminiService
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  
  def initialize
    @api_key = Rails.application.credentials.gemini_api_key
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
  
  def generate_summary(text)
    return nil if text.blank?
    
    uri = URI("#{BASE_URL}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    
    prompt = "You are an expert assistant trained in biblical teachings and christian theology and summarizing spoken content into clear, structured, and engaging text. Given the following transcript of a Christian-related talk (sermon, lecture, workshop, or discussion), generate a well-organized and comprehensive summary. Focus on key points, main ideas, and practical takeaways, ensuring readability and logical flow. You should highlight and provide full reference. Maintain accuracy while condensing information. Avoid unnecessary repetition and include relevant Bible references where applicable. Format in markdown for clarity. Here's the transcript:\n\n#{text}"
    
    # prompt = "You are an expert assistant trained in biblical teachings and christian theology. Summarize the following dermon transcript in a faith-based format with these sections: 
    
    # 1. Sermon title and theme
    # 2. Main points and takeaways (structured and bullet points)
    # 3. Faith application (how should a christian apply this message?)
    # 4. Suggested prayer (A short prayer based on the sermon theme)

    # prompt = "You are an expert assistant trained in biblical teachings and Christian theology. Analyze the following sermon transcript and create a structured summary with these sections:

    # 1. Main Theme: One sentence capturing the core message
    # 2. Key Biblical References: List and briefly explain relevant scripture passages
    # 3. Core Theological Topics: Identify and explain 2-3 main theological themes
    # 4. Key Points: 3-5 bullet points of essential takeaways
    # 5. Application: 2-3 practical ways to apply this message

    # Format in markdown for clarity. Here's the transcript:
    
    # :\n\n#{text}"
    
    request.body = {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
        }
      ]
    }.to_json
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      if result["candidates"] && !result["candidates"].empty?
        markdown_text = result["candidates"][0]["content"]["parts"][0]["text"]
        # Convert markdown to HTML for ActionText
        html_content = @markdown.render(markdown_text)
        return html_content
      else
        "Unable to generate summary."
      end
    else
      Rails.logger.error("Gemini API error: #{response.body}")
      "Error generating summary. Please try again later."
    end
  rescue StandardError => e
    Rails.logger.error("Gemini API error: #{e.message}")
    "Error generating summary. Please try again later."
  end
end