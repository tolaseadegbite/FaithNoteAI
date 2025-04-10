module ChatConversation
  class BibleChatConversationService
    def self.create(user, message_content, translation = "KJV")
      conversation = nil
      message = nil
      assistant_message = nil
      
      ActiveRecord::Base.transaction do
        # Create the conversation with a summarized title
        title = TitleGeneratorService.generate_title(message_content)
        
        conversation = user.bible_chat_conversations.new(
          title: title
        )
        
        if conversation.save
          # Create the first message
          message = conversation.bible_chat_messages.new(
            content: message_content,
            role: "user",
            user: user,
            translation: translation
          )
          
          if message.save
            # Create a placeholder assistant message
            assistant_message = conversation.bible_chat_messages.create!(
              content: "Searching the Bible...",
              role: "assistant",
              user: user,
              processing: true,
              translation: translation
            )
            
            # Invalidate caches
            invalidate_conversation_cache(user)
            invalidate_messages_cache(conversation)
          end
        end
      end
      
      # Enqueue the job to process the AI response OUTSIDE the transaction
      if message&.persisted? && assistant_message&.persisted?
        BibleChatJob.perform_later(message, translation, assistant_message.id)
      end
      
      return {
        conversation: conversation,
        message: message,
        errors: (conversation&.errors&.full_messages || []) + (message&.errors&.full_messages || [])
      }
    end
    
    def self.destroy(conversation)
      user = conversation.user
      result = conversation.destroy
      
      if result
        invalidate_conversation_cache(user)
      end
      
      result
    end
    
    private
    
    def self.invalidate_conversation_cache(user)
      Rails.cache.delete(CacheKeys.user_conversations_timestamp_key(user.id))
      Rails.cache.delete(CacheKeys.user_conversations_count_key(user.id))
      Rails.logger.info "Invalidated conversation cache for user #{user.id}"
    end
    
    def self.invalidate_messages_cache(conversation)
      Rails.cache.delete(CacheKeys.conversation_messages_timestamp_key(conversation.id))
      Rails.cache.delete(CacheKeys.conversation_messages_count_key(conversation.id))
      Rails.logger.info "Invalidated messages cache for conversation #{conversation.id}"
    end
  end
end