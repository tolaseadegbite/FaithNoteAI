class BibleVersesController < ApplicationController
  include BibleConstants
  
  before_action :set_bible_books, only: [:index, :show, :chapter]
  before_action :set_translations, only: [:index, :show, :chapter, :search]

  def index
    # Display all Bible books
    @old_testament_books = OLD_TESTAMENT_BOOKS
    @new_testament_books = NEW_TESTAMENT_BOOKS
    @translation = params[:translation] || "KJV"
  end

  def show
    # Show a specific verse
    @translation = params[:translation] || "KJV"
    @verse = BibleVerse.find_verse(params[:book], params[:chapter].to_i, params[:verse].to_i, @translation)
    
    if @verse.nil?
      flash[:alert] = "Verse not found"
      redirect_to bible_verses_path
    end
  end

  def chapter
    # Show all verses in a chapter
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @translation = params[:translation] || "KJV"
    
    @verses = BibleVerse.find_chapter(@book, @chapter, @translation)
    
    if @verses.empty?
      flash[:alert] = "Chapter not found"
      redirect_to bible_verses_path
      return
    end
    
    # Get chapter count for the book
    @chapter_count = BibleVerse.chapter_count_for_book(@book, @translation)
  end

  def search
  @query = params[:q]
  @highlight_query = @query.downcase if @query.present?
  @translation = params[:translation] || "KJV"
  
  begin
    search_result = BibleVerseSearchService.new(
      @query, 
      translation: @translation,
      page: params[:page] || 1
    ).search
    
    case search_result[:type]
    when :verse
      redirect_to bible_verse_path(
        book: search_result[:verse].book, 
        chapter: search_result[:verse].chapter, 
        verse: search_result[:verse].verse, 
        translation: @translation
      )
      return
    when :chapter
      redirect_to bible_chapter_path(
        book: search_result[:book], 
        chapter: search_result[:chapter], 
        translation: @translation
      )
      return
    when :search_results
      @pagy, @results = pagy(search_result[:results], items: 20)
    when :empty
      @results = []
      @pagy = Pagy.new(count: 0)
      flash.now[:notice] = search_result[:message] if search_result[:message].present?
    end
  rescue StandardError => e
    # Log the error
    Rails.logger.error("Bible search error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    # Set empty results and show an error message
    @results = []
    @pagy = Pagy.new(count: 0)
    flash.now[:alert] = "An error occurred while searching. Please try again."
  end
end

  private

  def set_bible_books
    @old_testament_books = OLD_TESTAMENT_BOOKS
    @new_testament_books = NEW_TESTAMENT_BOOKS
  end
  
  def set_translations
    @translations = TRANSLATIONS
    @translation = params[:translation] || "KJV"
  end
end