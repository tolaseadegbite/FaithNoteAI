class NotesController < ApplicationController
  before_action :find_note, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @notes = pagy_keyset(current_user.notes.ordered, limit: 21)
    # @notes = current_user.notes.ordered
  end

  def show
    @current_tab = params[:tab] || 'transcription'
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

  def generate_summary
    transcription = params[:transcription]
    
    if transcription.blank?
      render json: { error: "Transcription cannot be empty" }, status: :unprocessable_entity
      return
    end
    
    summary = GeminiService.new.generate_summary(transcription)
    
    if summary
      render json: { summary: summary }
    else
      render json: { error: "Failed to generate summary" }, status: :unprocessable_entity
    end
  end

  def process_audio
    if params[:audio_file].present?
      begin
        # Store the original audio file for later attachment
        audio_file = params[:audio_file]
        
        # Transcribe the audio
        transcription = ElevenlabsService.new.transcribe(audio_file)
        
        if transcription
          # Generate summary if requested
          summary = nil
          if params[:generate_summary] == "true"
            summary = GeminiService.new.generate_summary(transcription)
          end
          
          # Return the transcription, summary, and the audio file
          render json: { 
            status: 'success',
            transcription: transcription,
            summary: summary.to_s,
            audio_file: audio_file
          }, status: :ok
        else
          render json: { errors: ['Failed to transcribe audio'], status: 'error' }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error("Audio processing error: #{e.message}")
        render json: { errors: ["Error processing audio: #{e.message}"], status: 'error' }, status: :unprocessable_entity
      end
    else
      render json: { errors: ['No audio file provided'], status: 'error' }, status: :unprocessable_entity
    end
  end
  
  private

  def notes_param
    params.require(:note).permit(:title, :transcription, :language, :audio_url, :summary, :audio_file)
  end

  def find_note
    @note = Note.find(params[:id])
  end
end
