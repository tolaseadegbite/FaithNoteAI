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
  
  def self.create_with_message(user, message_content, translation)
    # Generate a title from the first message
    title = message_content.truncate(30)
    
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
end
