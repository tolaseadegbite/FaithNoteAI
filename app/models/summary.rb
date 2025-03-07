# == Schema Information
#
# Table name: summaries
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  format     :string           default("bullet_point"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  talk_id    :bigint           not null
#
# Indexes
#
#  index_summaries_on_talk_id  (talk_id)
#
# Foreign Keys
#
#  fk_rails_...  (talk_id => talks.id)
#
class Summary < ApplicationRecord
  belongs_to :talk
end
