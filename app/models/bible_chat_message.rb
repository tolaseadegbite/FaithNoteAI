# == Schema Information
#
# Table name: bible_chat_messages
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  processing :boolean          default(FALSE)
#  role       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_bible_chat_messages_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class BibleChatMessage < ApplicationRecord
  belongs_to :user

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  
  scope :ordered, -> { order(created_at: :asc) }
  
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
