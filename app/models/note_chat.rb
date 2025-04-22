# == Schema Information
#
# Table name: note_chats
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  processing :boolean          default(FALSE)
#  role       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  note_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_note_chats_on_note_id  (note_id)
#  index_note_chats_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (note_id => notes.id)
#  fk_rails_...  (user_id => users.id)
#
class NoteChat < ApplicationRecord
  belongs_to :note, counter_cache: true
  belongs_to :user
  
  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  
  scope :ordered, -> { order(created_at: :asc) }
  
  # Add broadcast for create - explicitly specify the partial
  after_create_commit -> { 
    broadcast_append_to note, 
                        target: "note_chat_messages", 
                        partial: "note_chats/note_chat" # Specify the partial to render
  }
  
  # Add broadcast for update - specify the target as the DOM ID of this chat
  after_update_commit -> { 
    broadcast_replace_to note, 
                         target: self, # Target the specific DOM ID of this chat message
                         partial: "note_chats/note_chat" # Specify the partial to render
  }
end
