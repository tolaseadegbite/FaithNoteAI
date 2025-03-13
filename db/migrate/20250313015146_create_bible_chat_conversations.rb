class CreateBibleChatConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_chat_conversations do |t|
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :bible_chat_conversations, [:user_id, :created_at]
  end
end