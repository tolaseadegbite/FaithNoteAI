module BibleChatMessagesHelper
  def conversation_messages_cache_key(conversation)
    # Cache the maximum updated_at value to avoid repeated queries
    max_updated_at = Rails.cache.fetch(CacheKeys.conversation_messages_timestamp_key(conversation.id), expires_in: 5.minutes) do
      Rails.logger.info "CACHE MISS: Fetching max updated_at for conversation #{conversation.id}"
      conversation.bible_chat_messages.maximum(:updated_at).to_i
    end
    
    # Include message count to handle deletion edge cases
    message_count = Rails.cache.fetch(CacheKeys.conversation_messages_count_key(conversation.id), expires_in: 5.minutes) do
      Rails.logger.info "CACHE MISS: Fetching message count for conversation #{conversation.id}"
      conversation.bible_chat_messages_count
    end
    
    Rails.logger.info "Using cache key: [#{conversation.id}, messages_list, #{max_updated_at}, #{message_count}]"
    
    # Return a consistent cache key format
    [conversation.id, "messages_list", max_updated_at, message_count]
  end
end