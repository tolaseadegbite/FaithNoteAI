class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :paystack_customer_code, :string
    add_index :users, :paystack_customer_code # Optional: Add an index if you plan to query by this often
  end
end