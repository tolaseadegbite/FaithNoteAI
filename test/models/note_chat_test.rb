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
require "test_helper"

class NoteChatTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
