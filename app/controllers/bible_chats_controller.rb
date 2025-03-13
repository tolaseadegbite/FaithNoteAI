class BibleChatsController < ApplicationController
  before_action :set_translations, only: [:index, :create]
  before_action :set_conversation, only: [:create]
  
  def index
    # Redirect to conversations index
    redirect_to bible_chat_conversations_path
  end
  
  def create
    @message = @conversation.bible_chat_messages.build(message_params)
    @message.user = current_user
    @translation = params[:translation] || "KJV"
    
    if @message.save
      # Process the message in the background
      BibleChatJob.perform_later(@message, @translation)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to bible_chat_conversation_path(@conversation) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def update_translation
    @translation = params[:translation]
    respond_to do |format|
      format.turbo_stream
    end
  end
  
  private
  
  def set_conversation
    @conversation = current_user.bible_chat_conversations.find(params[:conversation_id])
  end
  
  def message_params
    params.require(:bible_chat_message).permit(:content).merge(role: "user")
  end
  
  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
  end
end