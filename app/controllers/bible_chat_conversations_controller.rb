class BibleChatConversationsController < ApplicationController
  include BibleVersesHelper
  before_action :set_translations, only: [:index, :show]
  before_action :set_conversation, only: [:show, :destroy]
  
  def index
    @conversations = current_user.bible_chat_conversations.ordered
    @conversation = BibleChatConversation.new
    @translation = params[:translation] || "KJV"
  end

  def show
    @conversations = current_user.bible_chat_conversations.ordered
    
    # Load all messages at once - no pagination
    @messages = @conversation.bible_chat_messages.includes(:user).ordered
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
    
    # Track query count for debugging/optimization
    @query_count = 0
    ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      @query_count += 1
    end
    
    @cache_stats = {
      hit: !@cache_miss,
      queries: @query_count || 0,
      messages: @messages.size
    }
  end

  def create
    # Use the service to create a conversation with the first message
    translation = params[:translation] || "KJV"
    
    if params[:message].present?
      # Create with initial message and trigger AI response
      result = ChatConversation::BibleChatConversationService.create(
        current_user, 
        params[:message],
        translation
      )
      
      if result[:conversation].persisted?
        # The service already creates the assistant message and enqueues the job
        redirect_to bible_chat_conversation_path(result[:conversation], translation: translation)
      else
        redirect_to bible_chat_conversations_path, alert: "Failed to create conversation: #{result[:errors].join(', ')}"
      end
    else
      # Create empty conversation (fallback)
      @conversation = current_user.bible_chat_conversations.new(title: params[:title] || "New Conversation")
      
      if @conversation.save
        redirect_to bible_chat_conversation_path(@conversation), notice: "Conversation created."
      else
        redirect_to bible_chat_conversations_path, alert: "Failed to create conversation."
      end
    end
  end

  def destroy
    @conversation.destroy
    redirect_to bible_chat_conversations_path, notice: "Conversation deleted."
  end

  private

  def set_translations
    @translations = cached_bible_translations
  end

  def set_conversation
    @conversation = current_user.bible_chat_conversations.find(params[:id])
  end

  def conversation_params
    # This is still useful for the fallback case
    params.require(:bible_chat_conversation).permit(:title)
  rescue ActionController::ParameterMissing
    { title: params[:title] || "New Conversation" }
  end
end