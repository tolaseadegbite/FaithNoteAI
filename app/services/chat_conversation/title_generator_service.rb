module ChatConversation
  class TitleGeneratorService
    def self.generate_title(message_content, max_length: 50)
      # Simple summarization logic:
      # 1. Remove special characters and extra whitespace
      # 2. Split into sentences and take the first one or two
      # 3. Ensure it's not too long
      
      # Clean the message
      cleaned_message = message_content.strip.gsub(/\s+/, ' ')
      
      # Split into sentences (basic implementation)
      sentences = cleaned_message.split(/[.!?]/).map(&:strip).reject(&:empty?)
      
      if sentences.empty?
        # Fallback if no clear sentences
        return cleaned_message.truncate(max_length)
      elsif sentences.first.length <= max_length
        # If first sentence is short enough, use it
        return sentences.first
      else
        # Try to extract key phrases or use smart truncation
        words = sentences.first.split
        
        # Take first N words that fit within max_length
        title = ""
        words.each do |word|
          if (title + " " + word).length <= max_length
            title += " " + word unless title.empty?
            title = word if title.empty?
          else
            break
          end
        end
        
        return title.end_with?('...') ? title : "#{title}..."
      end
    end
  end
end