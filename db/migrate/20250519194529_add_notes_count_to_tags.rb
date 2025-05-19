class AddNotesCountToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :notes_count, :integer, default: 0
  end
end
