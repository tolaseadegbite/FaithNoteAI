class CreateBibleChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_chat_messages do |t|
      t.text :content, null: false
      t.string :role, null: false
      t.boolean :processing, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end