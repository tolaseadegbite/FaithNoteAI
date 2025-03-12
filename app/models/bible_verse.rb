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
  
  # Class methods for lookup with caching
  def self.find_verse(book, chapter, verse, translation = "KJV", language = "en")
    # Normalize book name for case-insensitive search
    normalized_book = book.is_a?(String) ? book.titleize : book
    
    Rails.cache.fetch("bible_verse/#{language}/#{translation}/#{normalized_book}/#{chapter}/#{verse}", expires_in: 1.week) do
      # Use ILIKE for case-insensitive search on PostgreSQL
      where("LOWER(book) = LOWER(?)", normalized_book)
        .where(chapter: chapter, verse: verse)
        .with_translation(translation)
        .with_language(language)
        .first
    end
  end

  def self.find_chapter(book, chapter, translation = "KJV", language = "en")
    # Normalize book name for case-insensitive search
    normalized_book = book.is_a?(String) ? book.titleize : book
    
    Rails.cache.fetch("bible_chapter/#{language}/#{translation}/#{normalized_book}/#{chapter}", expires_in: 1.week) do
      # Use ILIKE for case-insensitive search on PostgreSQL
      where("LOWER(book) = LOWER(?)", normalized_book)
        .where(chapter: chapter)
        .with_translation(translation)
        .with_language(language)
        .order(:verse)
        .to_a
    end
  end
  
  # Format reference (e.g., "John 3:16 (KJV)")
  def reference
    base = "#{book} #{chapter}:#{verse}"
    translation == "KJV" && language == "en" ? base : "#{base} (#{translation}, #{language_name})"
  end
  
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
