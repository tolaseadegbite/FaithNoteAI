class AddConversationToBibleChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :bible_chat_messages, :bible_chat_conversation, null: true, foreign_key: true
    
    # Add an index for performance
    add_index :bible_chat_messages, [:bible_chat_conversation_id, :created_at], name: 'index_messages_on_conversation_and_created_at'
  end
end