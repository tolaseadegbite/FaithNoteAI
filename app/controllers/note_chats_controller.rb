class NoteChatsController < ApplicationController
  before_action :set_note
  
  def create
    @note_chat = @note.note_chats.build(note_chat_params)
    @note_chat.user = current_user
    @note_chat.role = "user"
    
    if @note_chat.save
      # Process the AI response asynchronously
      ProcessNoteChatJob.perform_later(@note_chat)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @note }
      end
    else
      respond_to do |format|
        format.html { redirect_to @note, alert: "Failed to send message" }
      end
    end
  end
  
  private
  
  def set_note
    @note = Note.find(params[:note_id])
  end
  
  def note_chat_params
    params.require(:note_chat).permit(:content)
  end
end