class ProcessNoteChatJob < ApplicationJob
  queue_as :default

  def perform(note_chat)
    return unless note_chat.role == "user"
    
    # Create an assistant message
    assistant_message = note_chat.note.note_chats.create!(
      user: note_chat.user,
      role: "assistant",
      content: "Thinking...",
      processing: true
    )
    
    # Get the note content for context
    note_content = note_chat.note.content.to_plain_text
    
    # Get previous messages for context
    previous_messages = note_chat.note.note_chats
      .where.not(id: [note_chat.id, assistant_message.id])
      .order(created_at: :asc)
      .last(10)
      .map { |msg| { role: msg.role, content: msg.content } }
    
    # Process the AI response
    response = GeminiService.new.chat_with_note(
      note_chat.content,
      note_content,
      previous_messages
    )
    
    # Process Bible verse references in the response
    processed_response = ChatConversation::BibleVerseProcessor.process_response(response, "KJV")
    
    # Update the assistant message with the processed response
    assistant_message.update!(
      content: processed_response,
      processing: false
    )
  end
end