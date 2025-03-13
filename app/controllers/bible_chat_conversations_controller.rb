class BibleChatConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :destroy]
  before_action :set_translations, only: [:index, :show, :create]
  
  def index
    @conversations = current_user.bible_chat_conversations.ordered
    @translation = params[:translation] || "KJV"
  end
  
  def show
    @messages = @conversation.bible_chat_messages.ordered
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
  end
  
  def create
    @conversation = current_user.bible_chat_conversations.create(
      title: "New Conversation" # Default title since there's no first message
    )
    
    # Only create a message if one was provided
    if params[:message].present?
      @message = @conversation.bible_chat_messages.create(
        content: params[:message],
        role: "user",
        user: current_user
      )
      
      # Process AI response if a message was sent
      BibleChatJob.perform_later(@message, params[:translation] || "KJV")
    end
    
    redirect_to bible_chat_conversation_path(@conversation, translation: params[:translation] || "KJV")
  end
  
  def destroy
    @conversation.destroy
    redirect_to bible_chat_conversations_path, notice: "Conversation deleted"
  end
  
  private
  
  def set_conversation
    @conversation = current_user.bible_chat_conversations.find(params[:id])
  end
  
  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
  end
end