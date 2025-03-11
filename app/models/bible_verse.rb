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
#  index_bible_verses_on_reference_and_translation  (book,chapter,verse,translation,language) UNIQUE
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
    Rails.cache.fetch("bible_verse/#{language}/#{translation}/#{book}/#{chapter}/#{verse}", expires_in: 1.week) do
      by_reference(book, chapter, verse)
        .with_translation(translation)
        .with_language(language)
        .first
    end
  end
  
  def self.find_chapter(book, chapter, translation = "KJV", language = "en")
    Rails.cache.fetch("bible_chapter/#{language}/#{translation}/#{book}/#{chapter}", expires_in: 1.week) do
      by_reference(book, chapter)
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
