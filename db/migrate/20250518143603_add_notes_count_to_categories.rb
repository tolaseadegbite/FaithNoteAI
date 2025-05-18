class AddNotesCountToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :notes_count, :integer
  end
end
