class BibleChatConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :destroy]  # Remove any other actions that don't exist
  
  def index
    @conversations = current_user.bible_chat_conversations.ordered
    @conversation = BibleChatConversation.new
  end

  def show
    @conversations = current_user.bible_chat_conversations.ordered
    
    ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      @query_count ||= 0
      @query_count += 1
    end

    @messages = Rails.cache.fetch(["bible_chat_messages", @conversation.id, @conversation.updated_at.to_i]) do
      @cache_miss = true
      @conversation.bible_chat_messages.ordered.includes(:user)
    end
    
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
    @translations = BibleConstants::TRANSLATIONS

    @cache_stats = {
      hit: !@cache_miss,
      queries: @query_count || 0
    }
  end

  def create
    @conversation = current_user.bible_chat_conversations.new(conversation_params)
    
    if @conversation.save
      redirect_to bible_chat_conversation_path(@conversation), notice: "Conversation created."
    else
      redirect_to bible_chat_conversations_path, alert: "Failed to create conversation."
    end
  end

  def destroy
    @conversation.destroy
    redirect_to bible_chat_conversations_path, notice: "Conversation deleted."
  end

  private

  def set_conversation
    @conversation = current_user.bible_chat_conversations.find(params[:id])
  end

  def conversation_params
    params.require(:bible_chat_conversation).permit(:title)
  end
end