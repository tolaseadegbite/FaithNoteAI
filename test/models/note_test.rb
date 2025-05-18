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
#  category_id      :bigint
#  user_id          :bigint           not null
#
# Indexes
#
#  index_notes_on_category_id  (category_id)
#  index_notes_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class NoteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
