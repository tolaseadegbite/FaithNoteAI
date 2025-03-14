class BibleChatConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :destroy]
  before_action :set_translations, only: [:index, :show, :create]
  before_action :ensure_conversation_ownership, only: [:show, :destroy]
  
  def index
    @conversations = current_user.bible_chat_conversations.ordered
    @translation = params[:translation] || "KJV"
  end
  
  def show
    @conversations = current_user.bible_chat_conversations.ordered
    @messages = @conversation.bible_chat_messages.ordered
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
  rescue ActiveRecord::RecordNotFound
    redirect_to bible_chat_conversations_path, alert: "Conversation not found"
  end
  
  def create
    return redirect_to bible_chat_conversations_path, alert: "Message cannot be empty" unless params[:message].present?
  
    @conversation = current_user.bible_chat_conversations.new(
      title: params[:message].truncate(50)
    )
    
    if @conversation.save
      @message = @conversation.bible_chat_messages.new(
        content: params[:message],
        role: "user",
        user: current_user,
        translation: params[:translation] || params[:bible_chat_message][:translation] || "KJV"
      )
      
      if @message.save
        translation = params[:translation] || params[:bible_chat_message][:translation] || "KJV"
        
        # Create a placeholder message that will be visible immediately
        @assistant_message = @conversation.bible_chat_messages.create(
          content: "Searching the Bible...",
          role: "assistant",
          user: current_user,
          processing: true,
          translation: translation
        )
        
        # Pass the assistant message ID to the job
        BibleChatJob.perform_later(@message, translation, @assistant_message.id)
        
        redirect_to bible_chat_conversation_path(@conversation, translation: translation), notice: "Conversation started"
      else
        @conversation.destroy # Clean up the conversation if message creation fails
        redirect_to bible_chat_conversations_path, alert: "Failed to create message: #{@message.errors.full_messages.join(', ')}"
      end
    else
      redirect_to bible_chat_conversations_path, alert: "Failed to create conversation: #{@conversation.errors.full_messages.join(', ')}"
    end
  end
  
  def destroy
    if @conversation.destroy
      redirect_to bible_chat_conversations_path, notice: "Conversation deleted successfully"
    else
      redirect_to bible_chat_conversation_path(@conversation), alert: "Failed to delete conversation"
    end
  rescue StandardError => e
    Rails.logger.error("Error deleting conversation: #{e.message}")
    redirect_to bible_chat_conversations_path, alert: "An error occurred while deleting the conversation"
  end
  
  private
  
  def set_conversation
    @conversation = BibleChatConversation.includes(:bible_chat_messages).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bible_chat_conversations_path, alert: "Conversation not found"
  end

  def ensure_conversation_ownership
    unless @conversation.user_id == current_user.id
      redirect_to bible_chat_conversations_path, alert: "You don't have permission to access that conversation."
    end
  end
  
  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
  end
end