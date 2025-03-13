# == Schema Information
#
# Table name: bible_chat_conversations
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_bible_chat_conversations_on_user_id                 (user_id)
#  index_bible_chat_conversations_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class BibleChatConversationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
