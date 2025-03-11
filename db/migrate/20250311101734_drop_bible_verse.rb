class DropBibleVerse < ActiveRecord::Migration[8.0]
  def change
    drop_table :bible_verses
  end
end
