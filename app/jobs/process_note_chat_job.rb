class ProcessNoteChatJob < ApplicationJob
  queue_as :default
  
  def perform(note_chat)
    note = note_chat.note
    user = note_chat.user
    
    # Create assistant message
    assistant_message = note.note_chats.create!(
      content: "Thinking...",
      role: "assistant",
      user: user,
      processing: true
    )
    
    # Get previous messages for context (limit to last 10 for performance)
    previous_messages = note.note_chats
                           .where.not(id: [note_chat.id, assistant_message.id])
                           .order(created_at: :desc)
                           .limit(10)
                           .to_a
                           .reverse
    
    # Add the current user message
    context_messages = previous_messages + [note_chat]
    
    # Get response from Gemini - fixed to properly access transcription
    response = GeminiService.new.chat_with_note_context(
      note_chat.content, 
      note.rich_text_transcription.to_plain_text,
      context_messages
    )
    
    # Update assistant message with response
    assistant_message.update!(
      content: response,
      processing: false
    )
  end
end