class NotesController < ApplicationController
  before_action :find_note, only: [:show, :edit, :update, :destroy]

  def index
    @notes = current_user.notes
  end

  def show
    
  end

  def new
    @note = Note.new
  end

  def create
    @note = current_user.notes.build(notes_param)
    if @note.save
      respond_to do |format|
        format.html { redirect_to @note, notice: "Note created successfully" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    
  end

  def update
    if @note.update(notes_param)
      respond_to do |format|
        format.html { redirect_to @note, notice: "Note updated successfully" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to notes_path, notice: "Note deleted successfully" }
    end
  end

  private

  def notes_param
    params.require(:note).permit(:title, :transcription, :language, :audio_url, :summary)
  end

  def find_note
    @note = Note.find(params[:id])
  end
end
