class AddBibleChatMessagesCountToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :bible_chat_conversations, :bible_chat_messages_count, :integer, default: 0, null: false
    
    # Reset counters for existing records
    reversible do |dir|
      dir.up do
        BibleChatConversation.find_each do |conversation|
          BibleChatConversation.reset_counters(conversation.id, :bible_chat_messages)
        end
      end
    end
  end
end