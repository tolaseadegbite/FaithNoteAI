module BibleChatConversationsHelper
  def conversation_cache_key(user)
    # Cache the maximum updated_at value to avoid repeated queries
    max_updated_at = Rails.cache.fetch("user_#{user.id}_max_conversation_timestamp", expires_in: 10.minutes) do
      user.bible_chat_conversations.maximum(:updated_at).to_i
    end
    
    # Include conversation count to handle deletion edge cases
    conversation_count = Rails.cache.fetch("user_#{user.id}_conversation_count", expires_in: 10.minutes) do
      user.bible_chat_conversations.count
    end
    
    # Return a consistent cache key format
    [user.id, "conversations_list", max_updated_at, conversation_count]
  end
  
  def translations_cache_key
    "bible_translations"
  end
end