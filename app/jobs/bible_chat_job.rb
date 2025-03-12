class BibleChatJob < ApplicationJob
  queue_as :default
  
  def perform(bible_chat_message, translation)
    user = bible_chat_message.user
    
    # Create a processing message first
    assistant_message = user.bible_chat_messages.create!(
      content: "Searching the Bible...",
      role: "assistant",
      processing: true
    )
    
    # Get response from Gemini
    response = GeminiService.new.chat_with_bible(bible_chat_message.content, translation)
    
    # Update the message with the actual response
    assistant_message.update!(
      content: response,
      processing: false
    )
  end
end