class BibleChatJob < ApplicationJob
  queue_as :default

  def perform(user_message, assistant_message, translation)
    # Get the user's question
    question = user_message.content

    # Find relevant Bible verses based on the question
    relevant_verses = find_relevant_verses(question, translation)
    
    # Generate a response using the relevant verses
    response = generate_response(question, relevant_verses)
    
    # Update the assistant message with the response
    assistant_message.update(content: response, processing: false)
  end

  private

  def find_relevant_verses(question, translation)
    # Extract key terms from the question
    key_terms = extract_key_terms(question)
    
    # Search for verses containing these terms
    verses = []
    key_terms.each do |term|
      # Limit to 3 verses per term to avoid overwhelming responses
      results = BibleVerse.where("content ILIKE ? AND translation = ?", "%#{term}%", translation)
                         .order(:book, :chapter, :verse)
                         .limit(3)
      verses.concat(results)
    end
    
    # Remove duplicates and limit to 5 most relevant verses
    verses.uniq.first(5)
  end

  def extract_key_terms(question)
    # Remove common words and extract key terms
    stop_words = %w[the and to of in a is that for it as with be this was by on not are]
    words = question.downcase.gsub(/[^\w\s]/, '').split
    
    # Filter out stop words and short words
    words.reject { |word| stop_words.include?(word) || word.length < 3 }
         .uniq
         .first(3) # Limit to 3 key terms
  end

  def generate_response(question, verses)
    return "I couldn't find any relevant Bible verses for your question." if verses.empty?
    
    # Create a response with the relevant verses
    response = "Here are some Bible verses that might help answer your question:\n\n"
    
    verses.each do |verse|
      response += "**#{verse.reference}**\n#{verse.content}\n\n"
    end
    
    response += "I hope these verses help with your question. If you'd like more specific guidance, please ask a more detailed question."
    
    response
  end
end