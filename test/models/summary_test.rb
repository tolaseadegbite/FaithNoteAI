# == Schema Information
#
# Table name: summaries
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  format     :string           default("bullet_point"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  note_id    :bigint           not null
#
# Indexes
#
#  index_summaries_on_note_id  (note_id)
#
# Foreign Keys
#
#  fk_rails_...  (note_id => notes.id)
#
require "test_helper"

class SummaryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
