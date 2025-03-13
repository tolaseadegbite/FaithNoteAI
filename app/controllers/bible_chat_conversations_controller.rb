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
    # Only create a conversation if a message is provided
    if params[:message].present?
      @conversation = current_user.bible_chat_conversations.create(
        title: params[:message].truncate(30) # Use message content for title
      )
      
      @message = @conversation.bible_chat_messages.create(
        content: params[:message],
        role: "user",
        user: current_user
      )
      
      # Process AI response
      BibleChatJob.perform_later(@message, params[:translation] || "KJV")
      
      redirect_to bible_chat_conversation_path(@conversation, translation: params[:translation] || "KJV")
    else
      # If no message, redirect to index
      redirect_to bible_chat_conversations_path
    end
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