class CreateBibleVerses < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_verses do |t|
      t.string :book, null: false
      t.integer :chapter, null: false
      t.integer :verse, null: false
      t.text :content, null: false
      t.string :translation, null: false, default: "KJV"
      t.string :language, null: false, default: "en"

      t.timestamps
    end

    add_index :bible_verses, [:book, :chapter, :verse, :translation, :language], unique: true, name: 'index_bible_verses_on_reference_and_translation'
  end
end