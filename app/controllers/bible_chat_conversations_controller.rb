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
    @translation = params[:translation] || "KJV"
    @conversation, @message = BibleChatConversation.create_with_message(
      current_user, 
      params[:message], 
      @translation
    )
    
    # Process the message in the background
    BibleChatJob.perform_later(@message, @translation)
    
    redirect_to bible_chat_conversation_path(@conversation)
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