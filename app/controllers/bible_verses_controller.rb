class BibleVersesController < ApplicationController
  include BibleConstants
  include CacheKeyConcern
  
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
    
    # Pre-load adjacent verses using the caching mechanism
    @prev_verse = if @verse.verse > 1
      BibleVerse.find_verse(@verse.book, @verse.chapter, @verse.verse - 1, @translation)
    else
      # For first verse in chapter, get last verse of previous chapter if exists
      last_verse_of_prev_chapter = @verse.chapter > 1 ? 
        BibleVerse.find_chapter_last_verse(@verse.book, @verse.chapter - 1, @translation) : 
        nil
    end
    
    @next_verse = BibleVerse.find_verse(@verse.book, @verse.chapter, @verse.verse + 1, @translation)
  end

  def chapter
    @translation = params[:translation] || "KJV"
    @book = params[:book]
    @chapter = params[:chapter].to_i
    
    # Cache the chapter count
    cache_key = bible_chapter_count_key("en", @translation, @book)
    
    @chapter_count = Rails.cache.fetch(cache_key, expires_in: 1.week) do
      BibleVerse.chapter_count_for_book(@book, @translation)
    end
    
    @verses = BibleVerse.find_chapter(@book, @chapter, @translation)
    
    if @verses.empty?
      flash[:alert] = "Chapter not found"
      redirect_to bible_verses_path
    end
    
    # Get the last verse of the previous chapter (if not first chapter)
    @prev_chapter_last_verse = if @chapter > 1
      BibleVerse.find_chapter_last_verse(@book, @chapter - 1, @translation)
    else
      nil
    end
    
    # Get the first verse of the next chapter (if available)
    @next_chapter_first_verse = BibleVerse.find_verse(@book, @chapter + 1, 1, @translation)
  end
  
  def search
    @query = params[:q]
    @translation = params[:translation] || "KJV"
    
    if @query.present?
      search_service = Bible::BibleVerseSearchService.new(
        @query, 
        translation: @translation,
        page: params[:page].to_i || 1,
        items_per_page: 20
      )
      
      result = search_service.search
      
      case result[:type]
      when :verse
        # Redirect to the specific verse
        redirect_to bible_verse_path(
          book: result[:verse].book, 
          chapter: result[:verse].chapter, 
          verse: result[:verse].verse,
          translation: @translation
        )
        return
      when :chapter
        # Redirect to the chapter view
        redirect_to bible_chapter_path(
          book: result[:book], 
          chapter: result[:chapter],
          translation: @translation
        )
        return
      when :search_results
        # Paginate the results
        @pagy, @results = pagy(result[:results], items: 20)
      when :empty
        @results = []
        flash.now[:notice] = result[:message] if result[:message]
      end
    else
      @results = []
    end
  end
  
  private
  
  def handle_reference_search
    # Parse the reference
    match = @query.match(/^([1-3]?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$/)
    book = match[1].strip
    chapter = match[2].to_i
    verse = match[3].to_i if match[3]
    
    if verse
      # Specific verse reference
      redirect_to bible_verse_path(book: book, chapter: chapter, verse: verse, translation: @translation)
    else
      # Chapter reference
      redirect_to bible_chapter_path(book: book, chapter: chapter, translation: @translation)
    end
  end
  
  def set_bible_books
    @bible_books = OLD_TESTAMENT_BOOKS + NEW_TESTAMENT_BOOKS
  end
  
  def set_translations
    @translations = Rails.cache.fetch(bible_translations_key, expires_in: 1.day) do
      TRANSLATIONS
    end
  end
end