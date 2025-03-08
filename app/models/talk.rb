# == Schema Information
#
# Table name: talks
#
#  id            :bigint           not null, primary key
#  audio_url     :string
#  language      :string           default("en")
#  summary       :text
#  title         :string           not null
#  transcription :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_talks_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Talk < ApplicationRecord
  belongs_to :user
  has_many :summaries, dependent: :destroy

  has_rich_text :body
  has_rich_text :summary
end
