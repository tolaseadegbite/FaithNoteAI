# == Schema Information
#
# Table name: notes
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
#  index_notes_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class NoteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
