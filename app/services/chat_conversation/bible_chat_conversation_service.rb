module ChatConversation
  class BibleChatConversationService
    def self.create(user, message_content, translation = "KJV")
      conversation = nil
      message = nil
      
      ActiveRecord::Base.transaction do
        # Create the conversation
        conversation = user.bible_chat_conversations.new(
          title: message_content.truncate(50)
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
            # Create a placeholder message that will be visible immediately
            assistant_message = conversation.bible_chat_messages.create(
              content: "Searching the Bible...",
              role: "assistant",
              user: user,
              processing: true,
              translation: translation
            )
            
            # Explicitly invalidate cache
            invalidate_conversation_cache(user)
            
            # Return all necessary objects
            return {
              conversation: conversation,
              message: message,
              assistant_message: assistant_message
            }
          else
            # Roll back if message creation fails
            raise ActiveRecord::Rollback
          end
        end
      end
      
      # If we get here, something failed
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
  end
end