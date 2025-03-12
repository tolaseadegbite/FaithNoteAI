class AddTranslationToBibleChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :bible_chat_messages, :translation, :string
  end
end
