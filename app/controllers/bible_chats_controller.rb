class BibleChatsController < ApplicationController
  before_action :set_translations, only: [:index, :create, :update_translation]
  before_action :set_conversation, only: [:create]
  
  def index
    # Redirect to conversations index
    redirect_to bible_chat_conversations_path
  end
  
  def create
    @conversation = current_user.bible_chat_conversations.find(params[:bible_chat_conversation_id])
    @message = @conversation.bible_chat_messages.build(message_params)
    @message.user = current_user
    @message.role = "user"
    @translation = params[:bible_chat_message][:translation] || params[:translation] || "KJV"
    @message.translation = @translation
    
    if @message.save
      # Process the AI response asynchronously
      BibleChatJob.perform_later(@message, @translation)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to bible_chat_conversation_path(@conversation, translation: @translation) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('new_bible_chat_message', partial: 'bible_chat_messages/form', locals: { message: @message }) }
        format.html { redirect_to bible_chat_conversation_path(@conversation, translation: @translation), alert: "Failed to send message" }
      end
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
    @conversation = current_user.bible_chat_conversations.find(params[:bible_chat_conversation_id])
  end
  
  def message_params
    params.require(:bible_chat_message).permit(:content, :translation).merge(role: "user")
  end
  
  def set_translations
    @translations = Rails.cache.fetch("bible_translations", expires_in: 1.week) do
      BibleConstants::TRANSLATIONS
    end
  end
end