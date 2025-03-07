class CreateBibleVerses < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_verses do |t|
      t.string :book, null: false
      t.integer :chapter, null: false
      t.integer :verse, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :bible_verses, [:book, :chapter, :verse], unique: true
  end
end
