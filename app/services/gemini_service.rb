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





  def chat_with_note_context(question, context)
    return "No context provided" if context.blank?
    
    uri = URI("#{BASE_URL}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    
    prompt = <<~PROMPT
      ou are an AI assistant designed to answer questions based on a transcribed Christian-related talk (sermon, lecture, workshop, or discussion).
      
      Context:
      #{context}
      
      User question: #{question}
      
      Answer concisely and accurately using only the provided context. If the question relates to biblical concepts, reference the Bible where applicable. Do not make assumptions beyond the given content. Structure answers clearly, ensuring theological accuracy and relevance.
      If the question cannot be answered based on the context, politely say so.
      
      Format your response using Markdown for better readability:
      - Use bullet points for lists
      - Use **bold** for emphasis
      - Use > for quotes
      - Use ### for headings
      - Use proper formatting for Bible verses (e.g., **John 3:16**)
    PROMPT
    
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
        # Convert markdown to HTML for proper formatting
        html_content = @markdown.render(markdown_text)
        return html_content
      else
        return "I couldn't find an answer to your question in the provided context."
      end
    else
      Rails.logger.error("Gemini API error: #{response.body}")
      return "I'm sorry, I encountered an error processing your request. Please try again."
    end
  rescue StandardError => e
    Rails.logger.error("Error in Gemini chat: #{e.message}")
    "I'm sorry, I encountered an error processing your request. Please try again."
  end
end