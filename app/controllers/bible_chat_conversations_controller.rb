class BibleChatConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :destroy]
  before_action :set_translations, only: [:index, :show, :create]
  
  def index
    @conversations = current_user.bible_chat_conversations.ordered
    @translation = params[:translation] || "KJV"
  end
  
  def show
    @conversations = current_user.bible_chat_conversations.ordered
    @messages = @conversation.bible_chat_messages.ordered
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
  end
  
  def create
    @conversation = current_user.bible_chat_conversations.create(
      title: "New Conversation"
    )
    
    # Check both params[:message] and params[:bible_chat_message][:message]
    message_content = params[:message] || params.dig(:bible_chat_message, :message)
    
    if message_content.present?
      @message = @conversation.bible_chat_messages.create(
        content: message_content,
        role: "user",
        user: current_user,
        translation: params[:translation]
      )
      
      # Process AI response
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