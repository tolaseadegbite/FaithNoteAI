# == Schema Information
#
# Table name: bible_chat_messages
#
#  id                         :bigint           not null, primary key
#  content                    :text             not null
#  processing                 :boolean          default(FALSE)
#  role                       :string           not null
#  translation                :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  bible_chat_conversation_id :bigint
#  user_id                    :bigint           not null
#
# Indexes
#
#  index_bible_chat_messages_on_bible_chat_conversation_id  (bible_chat_conversation_id)
#  index_bible_chat_messages_on_user_id                     (user_id)
#  index_messages_on_conversation_and_created_at            (bible_chat_conversation_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (bible_chat_conversation_id => bible_chat_conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class BibleChatMessage < ApplicationRecord
  belongs_to :user
  belongs_to :bible_chat_conversation, optional: true

  validates :content, presence: true, length: { maximum: 10000 }
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  
  scope :ordered, -> { order(created_at: :asc) }
  scope :for_conversation, ->(conversation_id) { where(bible_chat_conversation_id: conversation_id).ordered }
  
  # Update the broadcast to specify the partial
  after_create_commit -> { 
    broadcast_append_to "bible_chat_#{user_id}", 
                        target: "bible_chat_messages", 
                        partial: "bible_chats/bible_chat_message"
  }
  
  # Update the broadcast to specify the partial
  after_update_commit -> {
    broadcast_replace_to "bible_chat_#{user_id}",
                         partial: "bible_chats/bible_chat_message"
  }
end
