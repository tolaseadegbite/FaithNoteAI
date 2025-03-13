# == Schema Information
#
# Table name: bible_chat_messages
#
#  id                         :bigint           not null, primary key
#  content                    :text             not null
#  processing                 :boolean          default(FALSE)
#  role                       :string           not null
#  translation                :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  bible_chat_conversation_id :bigint
#  user_id                    :bigint           not null
#
# Indexes
#
#  index_bible_chat_messages_on_bible_chat_conversation_id  (bible_chat_conversation_id)
#  index_bible_chat_messages_on_user_id                     (user_id)
#  index_messages_on_conversation_and_created_at            (bible_chat_conversation_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (bible_chat_conversation_id => bible_chat_conversations.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class BibleChatMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
