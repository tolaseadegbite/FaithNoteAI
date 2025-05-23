# == Schema Information
#
# Table name: bible_chat_conversations
#
#  id                        :bigint           not null, primary key
#  bible_chat_messages_count :integer          default(0), not null
#  title                     :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  user_id                   :bigint           not null
#
# Indexes
#
#  index_bible_chat_conversations_on_user_id                 (user_id)
#  index_bible_chat_conversations_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class BibleChatConversation < ApplicationRecord

  belongs_to :user, counter_cache: true
  has_many :bible_chat_messages, dependent: :destroy
  
  validates :title, presence: true
  
  scope :ordered, -> { order(updated_at: :desc) }

  # Add callback to invalidate cache when conversation is destroyed
  # after_destroy :invalidate_conversation_cache
  
  def self.create_with_message(user, message_content, translation)
    # Generate a title from the first message using the service
    title = ChatConversation::TitleGeneratorService.generate_title(message_content)
    
    # Create the conversation
    conversation = user.bible_chat_conversations.create!(title: title)
    
    # Create the first message
    message = conversation.bible_chat_messages.create!(
      content: message_content,
      role: "user",
      user: user,
      translation: translation
    )
    
    return conversation, message
  end

  # private
  
  # def invalidate_conversation_cache
  #   Rails.cache.delete(CacheKeys.user_conversations_timestamp_key(user_id))
  #   Rails.cache.delete(CacheKeys.user_conversations_count_key(user_id))
  #   Rails.logger.info "Invalidated conversation cache for user #{user_id} from model callback"
  # end
end
