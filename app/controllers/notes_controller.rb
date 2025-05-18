class NotesController < ApplicationController
  before_action :find_note, only: [:show, :edit, :update, :destroy]
  before_action :find_categories, only: [:new, :edit, :create, :update, :show]

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

  # POST /notes/process_audio
  def process_audio
    # Delegate audio processing logic to the service
    result = AudioProcessingService.new(params).process

    # Render the response based on the service result
    if result[:error]
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    else
      render json: { job_id: result[:job_id] }, status: :ok
    end
  end

  def check_transcription_status
    # Delegate status checking logic to the service
    result = TranscriptionStatusService.new(params).check

    # Render the response provided by the service
    render json: result[:body], status: result[:status]
  end

  private

  def notes_param
    # Ensure :audio_file is permitted if you intend to save it directly to the model later
    params.require(:note).permit(:title, :transcription, :language, :audio_url, :summary, :audio_file, :category_id)
  end

  def find_note
    @note = Note.find(params[:id])
  end

  def find_categories
    @categories = current_user.categories
  end
end
