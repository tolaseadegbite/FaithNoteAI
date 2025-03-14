class AddNoteChatsCountToNotes < ActiveRecord::Migration[7.1]
  def change
    add_column :notes, :note_chats_count, :integer, default: 0, null: false
    
    # Reset counters for existing records
    reversible do |dir|
      dir.up do
        Note.find_each do |note|
          Note.reset_counters(note.id, :note_chats)
        end
      end
    end
  end
end