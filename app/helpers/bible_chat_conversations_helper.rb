module BibleChatConversationsHelper
  include Pagy::Frontend
  
  def conversation_cache_key(user)
    # Cache the maximum updated_at value to avoid repeated queries
    max_updated_at = Rails.cache.fetch(CacheKeys.user_conversations_timestamp_key(user.id), expires_in: 10.minutes) do
      user.bible_chat_conversations.maximum(:updated_at).to_i
    end
    
    # Include conversation count to handle deletion edge cases
    conversation_count = Rails.cache.fetch(CacheKeys.user_conversations_count_key(user.id), expires_in: 10.minutes) do
      user.bible_chat_conversations.count
    end
    
    # Return a consistent cache key format
    [user.id, "conversations_list", max_updated_at, conversation_count]
  end
  
  def translations_cache_key(version = 1)
    CacheKeys.bible_translations_key(version)
  end
  
  def cached_bible_translations
    cache_key = translations_cache_key
    cached = Rails.cache.exist?(cache_key)
    
    translations = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      Rails.logger.info "CACHE MISS: Bible translations cache being generated"
      BibleConstants::TRANSLATIONS
    end
    
    Rails.logger.info "CACHE #{cached ? 'HIT' : 'MISS'}: Bible translations (#{translations.count} items)"
    translations
  end
end