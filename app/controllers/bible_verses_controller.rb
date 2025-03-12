class BibleVersesController < ApplicationController
  before_action :set_bible_books, only: [:index, :show, :chapter]
  before_action :set_translations, only: [:index, :show, :chapter]

  def index
    # Display all Bible books
    @old_testament_books = old_testament_books
    @new_testament_books = new_testament_books
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
    @chapter_count = BibleVerse.where(book: @book, translation: @translation)
                              .select(:chapter).distinct.count
  end

  def search
    @query = params[:q]
    @highlight_query = @query.downcase if @query.present?
    @translation = params[:translation] || "KJV"
    set_translations
    
    if @query.present?
      # Try to parse as a reference first (e.g., "John 3:16")
      if @query.match?(/^([1-3]?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$/i)
        # Use match instead of match? to capture the groups
        match_data = @query.match(/^([1-3]?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$/i)
        
        if match_data
          book = match_data[1].strip
          chapter = match_data[2].to_i
          verse = match_data[3].to_i if match_data[3]
          
          if verse
            # Specific verse reference
            @verse = BibleVerse.find_verse(book, chapter, verse, @translation)
            if @verse
              redirect_to bible_verse_path(book: @verse.book, chapter: @verse.chapter, verse: @verse.verse, translation: @translation)
              return
            end
          else
            # Chapter reference
            @verses = BibleVerse.find_chapter(book, chapter, @translation)
            if @verses.any?
              redirect_to bible_chapter_path(book: book, chapter: chapter, translation: @translation)
              return
            end
          end
        end
      end
      
      # If not a valid reference or not found, search by content with pagination
      @pagy, @results = pagy(
        BibleVerse.where("content ILIKE ? AND translation = ?", "%#{@query}%", @translation)
                .order(:book, :chapter, :verse),
        items: 20
      )
    else
      @results = []
      @pagy = Pagy.new(count: 0)
    end
  end

  private

  def set_bible_books
    @old_testament_books = old_testament_books
    @new_testament_books = new_testament_books
  end
  
  def set_translations
    @translations = ["KJV", "ASV", "BBE", "DARBY", "WEBSTER", "WEB", "YLT"]
    @translation = params[:translation] || "KJV"
  end

  def old_testament_books
    [
      "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
      "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
      "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
      "Ezra", "Nehemiah", "Esther", "Job", "Psalms",
      "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah",
      "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
      "Hosea", "Joel", "Amos", "Obadiah", "Jonah",
      "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
      "Zechariah", "Malachi"
    ]
  end

  def new_testament_books
    [
      "Matthew", "Mark", "Luke", "John", "Acts",
      "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
      "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
      "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
      "James", "1 Peter", "2 Peter", "1 John", "2 John",
      "3 John", "Jude", "Revelation"
    ]
  end
end