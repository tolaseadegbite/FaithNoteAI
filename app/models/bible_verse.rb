# == Schema Information
#
# Table name: bible_verses
#
#  id          :bigint           not null, primary key
#  book        :string           not null
#  chapter     :integer          not null
#  content     :text             not null
#  language    :string           default("en"), not null
#  translation :string           default("KJV"), not null
#  verse       :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bible_verses_on_book_and_chapter_and_translation  (book,chapter,translation)
#  index_bible_verses_on_content_trigram                   (content) USING gin
#  index_bible_verses_on_reference_and_translation         (book,chapter,verse,translation,language) UNIQUE
#  index_bible_verses_on_translation                       (translation)
#
class BibleVerse < ApplicationRecord
  # Validations
  validates :book, :chapter, :verse, :content, :translation, :language, presence: true
  
  # Scopes
  scope :by_reference, ->(book, chapter, verse = nil) {
    if verse.present?
      where(book: book, chapter: chapter, verse: verse)
    else
      where(book: book, chapter: chapter)
    end
  }
  
  scope :with_translation, ->(translation = "KJV") {
    where(translation: translation)
  }
  
  scope :with_language, ->(language = "en") {
    where(language: language)
  }

  # class method for chapter count
  def self.chapter_count_for_book(book, translation = "KJV")
    where(book: book, translation: translation)
      .select(:chapter).distinct.count
  end
  
  # Class methods for lookup with caching
  def self.find_verse(book, chapter, verse, translation = "KJV", language = "en")
    # Normalize book name for case-insensitive search
    normalized_book = book.is_a?(String) ? book.titleize : book
    
    # Cache key for the requested verse
    cache_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/#{verse}"
    
    # Log cache status
    cached = Rails.cache.exist?(cache_key)
    Rails.logger.info "BibleVerse Cache #{cached ? 'HIT' : 'MISS'}: #{cache_key}"
    
    # Fetch the requested verse
    current_verse = Rails.cache.fetch(cache_key, expires_in: 1.week) do
      where("LOWER(book) = LOWER(?)", normalized_book)
        .where(chapter: chapter, verse: verse)
        .with_translation(translation)
        .with_language(language)
        .first
    end
    
    # If we have a verse, cache adjacent verses (regardless of whether current verse was cached)
    if current_verse
      # Cache previous verse (if not first verse in chapter)
      if verse > 1
        prev_cache_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/#{verse-1}"
        # Only fetch from DB if not already cached
        unless Rails.cache.exist?(prev_cache_key)
          prev_verse = where("LOWER(book) = LOWER(?)", normalized_book)
            .where(chapter: chapter, verse: verse-1)
            .with_translation(translation)
            .with_language(language)
            .first
          Rails.cache.write(prev_cache_key, prev_verse, expires_in: 1.week) if prev_verse
          Rails.logger.info "BibleVerse Cache PREFETCH: #{prev_cache_key}"
        end
      end
      
      # Cache next verse
      next_cache_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/#{verse+1}"
      # Only fetch from DB if not already cached
      unless Rails.cache.exist?(next_cache_key)
        next_verse = where("LOWER(book) = LOWER(?)", normalized_book)
          .where(chapter: chapter, verse: verse+1)
          .with_translation(translation)
          .with_language(language)
          .first
        Rails.cache.write(next_cache_key, next_verse, expires_in: 1.week) if next_verse
        Rails.logger.info "BibleVerse Cache PREFETCH: #{next_cache_key}"
      end
    end
    
    current_verse
  end

  def self.find_chapter(book, chapter, translation = "KJV", language = "en")
    # Normalize book name for case-insensitive search
    normalized_book = book.is_a?(String) ? book.titleize : book
    
    cache_key = "bible_chapter/#{language}/#{translation}/#{normalized_book}/#{chapter}"
    
    # Log cache status
    cached = Rails.cache.exist?(cache_key)
    Rails.logger.info "BibleChapter Cache #{cached ? 'HIT' : 'MISS'}: #{cache_key}"
    
    verses = Rails.cache.fetch(cache_key, expires_in: 1.week) do
      # Use LOWER for case-insensitive search
      where("LOWER(book) = LOWER(?)", normalized_book)
        .where(chapter: chapter)
        .with_translation(translation)
        .with_language(language)
        .order(:verse)
        .to_a
    end
    
    # If we have verses for this chapter, cache all individual verses
    # This helps with navigation within and between chapters
    if verses.present?
      verses.each do |verse|
        verse_cache_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/#{verse.verse}"
        unless Rails.cache.exist?(verse_cache_key)
          Rails.cache.write(verse_cache_key, verse, expires_in: 1.week)
          Rails.logger.info "BibleVerse Cache PREFETCH: #{verse_cache_key}"
        end
      end
      
      # Also cache the last verse with a special key for chapter navigation
      last_verse = verses.last
      last_verse_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/last"
      unless Rails.cache.exist?(last_verse_key)
        Rails.cache.write(last_verse_key, last_verse, expires_in: 1.week)
        Rails.logger.info "BibleVerse Cache PREFETCH: #{last_verse_key}"
      end
    end
    
    verses
  end

  def self.find_chapter_last_verse(book, chapter, translation = "KJV", language = "en")
    normalized_book = book.is_a?(String) ? book.titleize : book
    
    cache_key = "bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/last"
    
    # Log cache status
    cached = Rails.cache.exist?(cache_key)
    Rails.logger.info "BibleVerse Cache #{cached ? 'HIT' : 'MISS'}: #{cache_key}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.week) do
      where("LOWER(book) = LOWER(?)", normalized_book)
        .where(chapter: chapter)
        .with_translation(translation)
        .with_language(language)
        .order(verse: :desc)
        .first
    end
  end
  
  # Format reference (e.g., "John 3:16 (KJV)")
  # Full text with reference
  def full_text
    "#{reference} - #{content}"
  end

  def reference
    base = "#{book} #{chapter}:#{verse}"
    if translation == "KJV" && language == "en"
      base
    elsif ["NIV", "NASB"].include?(translation) && language == "en"
      "#{base} (#{translation})"
    else
      "#{base} (#{translation}, #{language_name})"
    end
  end
  
  private
  
  def language_name
    case language
    when "en" then "English"
    when "es" then "Spanish"
    when "fr" then "French"
    when "de" then "German"
    when "yo" then "Yoruba"
    when "ha" then "Hausa"
    when "ig" then "Igbo"
    else language
    end
  end
end