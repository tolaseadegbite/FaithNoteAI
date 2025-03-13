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
    return redirect_to bible_chat_conversations_path unless params[:message].present?
  
    @conversation = current_user.bible_chat_conversations.create(
      title: params[:message].truncate(50)
    )
    
    @message = @conversation.bible_chat_messages.create(
      content: params[:message],
      role: "user",
      user: current_user,
      translation: params[:translation] || params[:bible_chat_message][:translation] || "KJV"
    )
    
    translation = params[:translation] || params[:bible_chat_message][:translation] || "KJV"
    BibleChatJob.perform_later(@message, translation)
    
    redirect_to bible_chat_conversation_path(@conversation, translation: translation)
  end
  
  def destroy
    @conversation.destroy
    redirect_to bible_chat_conversations_path, alert: "Conversation deleted"
  end
  
  private
  
  def set_conversation
    @conversation = current_user.bible_chat_conversations.find(params[:id])
  end
  
  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
  end
end