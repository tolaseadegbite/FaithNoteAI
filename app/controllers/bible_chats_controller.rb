class BibleChatsController < ApplicationController
  before_action :set_translations, only: [:index, :create]

  def index
    @messages = current_user.bible_chat_messages.ordered
    @message = BibleChatMessage.new
    @translation = params[:translation] || "KJV"
  end

  def create
    @message = current_user.bible_chat_messages.build(message_params)
    @translation = params[:translation] || "KJV"
  
    if @message.save
      # Process the message in the background
      BibleChatJob.perform_later(@message, @translation)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to bible_chats_path(translation: @translation) }
      end
    else
      @messages = current_user.bible_chat_messages.ordered
      render :index, status: :unprocessable_entity
    end
  end

  def clear
    current_user.bible_chat_messages.destroy_all
    redirect_to bible_chats_path, notice: "Chat history cleared"
  end

  private

  def message_params
    params.require(:bible_chat_message).permit(:content).merge(role: "user")
  end

  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
    @translation = params[:translation] || "KJV"
  end
end