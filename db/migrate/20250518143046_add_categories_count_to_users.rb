class AddCategoriesCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :categories_count, :integer
  end
end
