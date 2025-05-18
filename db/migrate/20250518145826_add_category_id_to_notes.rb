class AddCategoryIdToNotes < ActiveRecord::Migration[8.0]
  def change
    add_reference :notes, :category, null: true, foreign_key: true
  end
end
