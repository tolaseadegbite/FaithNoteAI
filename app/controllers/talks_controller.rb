class TalksController < ApplicationController
  before_action :find_talk, only: [:show, :edit, :update, :destroy]

  def index
    @talks = current_user.talks
  end

  def show
    
  end

  def new
    @talk.new
  end

  def create
    current_user.talks.build
    if @talk.save
      respond_to do |format|
        format.html { redirect_to @talk, notice: "Talk created successfully" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    
  end

  def update
    if @talk.update(talks_param)
      respond_to do |format|
        format.html { redirect_to @talk, notice: "Talk updated successfully" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @talk.destroy
    respond_to do |format|
      format.html { redirect_to talks_path, notice: "Talk deleted successfully" }
    end
  end

  private

  def talks_param
    params.require(:talk).permit(:title, :transcription, :language, :audio_url, :summary)
  end

  def find_talk
    @talk = Talk.find(params[:id])
  end
end
