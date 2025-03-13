class BibleChatJob < ApplicationJob
  queue_as :default
  
  def perform(bible_chat_message, translation)
    user = bible_chat_message.user
    conversation = bible_chat_message.bible_chat_conversation
    
    # Create a processing message first
    assistant_message = conversation.bible_chat_messages.create!(
      content: "Searching the Bible...",
      role: "assistant",
      user: user,
      processing: true,
      translation: translation
    )
    
    # Get previous messages for context (limit to last 10 for performance)
    previous_messages = conversation.bible_chat_messages
                                   .where.not(id: [bible_chat_message.id, assistant_message.id])
                                   .order(created_at: :desc)
                                   .limit(10)
                                   .to_a
                                   .reverse
    
    # Add the current user message
    context_messages = previous_messages + [bible_chat_message]
    
    # Get response from Gemini with context
    response = GeminiService.new.chat_with_bible(
      bible_chat_message.content, 
      translation,
      context_messages
    )
    
    # Update the message with the actual response
    assistant_message.update!(
      content: response,
      processing: false
    )
  end
end