class AddCategoriesCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :categories_count, :integer, default: 0
  end
end
