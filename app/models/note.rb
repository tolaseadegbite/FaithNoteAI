# == Schema Information
#
# Table name: notes
#
#  id               :bigint           not null, primary key
#  audio_url        :string
#  language         :string           default("en")
#  note_chats_count :integer          default(0), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_notes_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Note < ApplicationRecord
  validates :title, :transcription, presence: true
  belongs_to :user, counter_cache: true
  has_many :summaries, dependent: :destroy
  has_many :note_chats, dependent: :destroy

  has_rich_text :transcription
  has_rich_text :summary

  scope :ordered, -> { order(id: :desc) }

  has_one_attached :audio_file
end
