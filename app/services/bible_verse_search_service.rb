class BibleVerseSearchService
  attr_reader :query, :translation, :page, :items_per_page

  def initialize(query, translation: "KJV", page: 1, items_per_page: 20)
    @query = query
    @translation = translation
    @page = page
    @items_per_page = items_per_page
  end

  def search
    return { type: :empty, message: "Please enter a search term" } unless query.present?

    # Try to parse as a reference first
    parsed_reference = BibleReferenceParser.parse(query)
    
    if parsed_reference
      result = search_by_reference(parsed_reference)
      return result if result
    end
    
    # If not a valid reference or not found, search by content
    search_by_content
  end

  private

  def search_by_reference(reference)
    if reference[:verse]
      # Specific verse reference
      verse = BibleVerse.find_verse(reference[:book], reference[:chapter], reference[:verse], translation)
      return { type: :verse, verse: verse } if verse
    else
      # Chapter reference
      verses = BibleVerse.find_chapter(reference[:book], reference[:chapter], translation)
      return { type: :chapter, book: reference[:book], chapter: reference[:chapter], verses: verses } if verses.any?
    end
    
    nil
  end

  def search_by_content
    results = BibleVerse.where("content ILIKE ? AND translation = ?", "%#{query}%", translation)
                       .order(:book, :chapter, :verse)
    
    { type: :search_results, results: results, query: query }
  end

  def empty_result
    { type: :empty }
  end
end