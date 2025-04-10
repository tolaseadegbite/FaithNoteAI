# A module containing cache key generation methods that can be used anywhere in the application
module CacheKeys
  # Bible verse cache keys
  def self.bible_verse_key(language, translation, book, chapter, verse)
    "bible/verse/#{language}/#{translation}/#{book}/#{chapter}/#{verse}"
  end
  
  def self.bible_chapter_key(language, translation, book, chapter)
    "bible/chapter/#{language}/#{translation}/#{book}/#{chapter}"
  end
  
  def self.bible_chapter_count_key(language, translation, book)
    "bible/chapter_count/#{language}/#{translation}/#{book}"
  end
  
  # User conversation cache keys
  def self.user_conversations_timestamp_key(user_id)
    "user/#{user_id}/conversations/max_timestamp"
  end
  
  def self.user_conversations_count_key(user_id)
    "user/#{user_id}/conversations/count"
  end
  
  # Bible translations cache key
  def self.bible_translations_key(version = 1)
    "app/bible/translations/v#{version}"
  end
  
  # Conversation messages cache keys
  def self.conversation_messages_timestamp_key(conversation_id)
    "conversation/#{conversation_id}/messages/max_timestamp"
  end
  
  def self.conversation_messages_count_key(conversation_id)
    "conversation/#{conversation_id}/messages/count"
  end
end