class CreateNoteChats < ActiveRecord::Migration[8.0]
  def change
    create_table :note_chats do |t|
      t.references :note, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :role, null: false
      t.boolean :processing, default: false

      t.timestamps
    end
  end
end