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





  def chat_with_note_context(question, context, context_messages = [])
    return "No context provided" if context.blank?
    
    uri = URI("#{BASE_URL}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    
    # Format the conversation history
    conversation_history = ""
    if context_messages.any?
      conversation_history = "Previous conversation:\n\n"
      context_messages.each do |msg|
        role = msg.role == "user" ? "User" : "Assistant"
        conversation_history += "#{role}: #{msg.content}\n\n"
      end
    end
    
    prompt = <<~PROMPT
      You are an AI assistant designed to answer questions based on a transcribed Christian-related talk (sermon, lecture, workshop, or discussion).
      
      Context:
      #{context}
      
      #{conversation_history}
      
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





  def chat_with_bible(question, translation = "KJV", context_messages = [])
    return "No question provided" if question.blank?
    
    uri = URI("#{BASE_URL}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    
    # Format the conversation history
    conversation_history = ""
    if context_messages.any?
      conversation_history = "Previous conversation:\n\n"
      context_messages.each do |msg|
        role = msg.role == "user" ? "User" : "Assistant"
        conversation_history += "#{role}: #{msg.content}\n\n"
      end
    end
    
    prompt = <<~PROMPT
      You are a knowledgeable Bible assistant trained to answer questions about scripture, theology, and biblical concepts.
      
      #{conversation_history}
      
      User question: #{question}
      
      Preferred Bible translation: #{translation}
      
      Important instructions:
      - Answer the question directly without phrases like "Here's an answer to..." or "I understand..."
      - Respond as if in a natural conversation
      - Cite relevant scripture verses with their references (e.g., John 3:16)
      - When quoting scripture, use the #{translation} translation
      - Maintain biblical accuracy in your responses
      
      Format your response using Markdown for better readability:
      - Use bullet points for lists
      - Use **bold** for emphasis and scripture references
      - Use > for quotes from scripture
      - Use ### for headings
      - Structure your answer clearly and concisely
      
      If you're unsure about an answer, acknowledge the limitations and suggest what scripture might be relevant.
      Remember to consider the conversation history when providing your response.
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
        return "I couldn't generate an answer to your Bible question."
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