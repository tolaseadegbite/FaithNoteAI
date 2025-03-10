class ProcessNoteChatJob < ApplicationJob
  queue_as :default
  
  def perform(note_chat)
    note = note_chat.note
    
    # Create a thinking message first
    thinking_message = note.note_chats.create!(
      user: note_chat.user,
      role: "assistant",
      content: "Thinking...",
      processing: true
    )
    
    # Get response from Gemini
    response = GeminiService.new.chat_with_note_context(
      note_chat.content, 
      note.transcription.to_plain_text
    )
    
    # Update the message with the actual response
    thinking_message.update!(
      content: response,
      processing: false
    )
  end
end