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
require "test_helper"

class BibleChatMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
