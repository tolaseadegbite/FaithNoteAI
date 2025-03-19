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
    # @messages = @conversation.bible_chat_messages.ordered
    @pagy, @messages = pagy_keyset(@conversation.bible_chat_messages.ordered)

    @messages = @messages.reverse

    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
  rescue ActiveRecord::RecordNotFound
    redirect_to bible_chat_conversations_path, alert: "Conversation not found"
  end
  
  def create
    return redirect_to bible_chat_conversations_path, alert: "Message cannot be empty" unless params[:message].present?
  
    translation = params[:translation] || params[:bible_chat_message][:translation] || "KJV"
    
    result = ChatConversation::BibleChatConversationService.create(
      current_user,
      params[:message],
      translation
    )
    
    if result[:conversation].persisted? && result[:message].persisted?
      @conversation = result[:conversation]
      @message = result[:message]
      @assistant_message = result[:assistant_message]
      
      # Start the background job
      BibleChatJob.perform_later(@message, translation, @assistant_message.id)
      
      redirect_to bible_chat_conversation_path(@conversation, translation: translation), notice: "Conversation started"
    else
      redirect_to bible_chat_conversations_path, alert: "Failed to create conversation: #{result[:errors].join(', ')}"
    end
  end
  
  def destroy
    if ChatConversation::BibleChatConversationService.destroy(@conversation)
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
    @translations = Rails.cache.fetch("bible_translations", expires_in: 1.week) do
      BibleConstants::TRANSLATIONS
    end
  end
end