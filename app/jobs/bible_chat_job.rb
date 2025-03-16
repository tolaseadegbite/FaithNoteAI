class BibleChatJob < ApplicationJob
  queue_as :default
  
  def perform(bible_chat_message, translation, assistant_message_id = nil)
    user = bible_chat_message.user
    conversation = bible_chat_message.bible_chat_conversation
    
    # Use the existing assistant message if provided, otherwise create a new one
    assistant_message = if assistant_message_id
                          BibleChatMessage.find(assistant_message_id)
                        else
                          # Create a processing message first
                          conversation.bible_chat_messages.create!(
                            content: "Searching the Bible...",
                            role: "assistant",
                            user: user,
                            processing: true,
                            translation: translation
                          )
                        end
    
    # Get previous messages for context (limit to last 5 messages)
    context_messages = conversation.bible_chat_messages
                                  .where.not(id: bible_chat_message.id)
                                  .where.not(id: assistant_message.id)
                                  .where(processing: false)
                                  .order(created_at: :desc)
                                  .limit(5)
                                  .reverse
    
    # Get response from Gemini with our hybrid approach
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