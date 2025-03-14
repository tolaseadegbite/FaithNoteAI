class AddNotesCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notes_count, :integer, default: 0, null: false
    
    # Reset counters for existing records
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :notes)
        end
      end
    end
  end
end