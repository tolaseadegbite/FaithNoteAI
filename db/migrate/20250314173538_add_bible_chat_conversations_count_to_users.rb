class AddBibleChatConversationsCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :bible_chat_conversations_count, :integer, default: 0, null: false
    
    # Reset counters for existing records
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :bible_chat_conversations)
        end
      end
    end
  end
end