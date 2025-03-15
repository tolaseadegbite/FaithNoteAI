module CacheKeyConcern
  extend ActiveSupport::Concern

  included do
    # Make class methods available as module methods
    extend ClassMethods
  end

  class_methods do
    def bible_verse_key(language, translation, book, chapter, verse)
      "bible/verse/#{language}/#{translation}/#{book}/#{chapter}/#{verse}"
    end
    
    def bible_chapter_key(language, translation, book, chapter)
      "bible/chapter/#{language}/#{translation}/#{book}/#{chapter}"
    end
    
    def bible_chapter_count_key(language, translation, book)
      "bible/chapter_count/#{language}/#{translation}/#{book}"
    end
    
    def user_conversations_timestamp_key(user_id)
      "user/#{user_id}/conversations/max_timestamp"
    end
    
    def user_conversations_count_key(user_id)
      "user/#{user_id}/conversations/count"
    end
    
    def bible_translations_key(version = 1)
      "app/bible/translations/v#{version}"
    end
  end
  
  # Instance methods that mirror the class methods
  def bible_verse_key(language, translation, book, chapter, verse)
    self.class.bible_verse_key(language, translation, book, chapter, verse)
  end
  
  def bible_chapter_key(language, translation, book, chapter)
    self.class.bible_chapter_key(language, translation, book, chapter)
  end
  
  def bible_chapter_count_key(language, translation, book)
    self.class.bible_chapter_count_key(language, translation, book)
  end
  
  def user_conversations_timestamp_key(user_id)
    self.class.user_conversations_timestamp_key(user_id)
  end
  
  def user_conversations_count_key(user_id)
    self.class.user_conversations_count_key(user_id)
  end
  
  def bible_translations_key(version = 1)
    self.class.bible_translations_key(version)
  end
end