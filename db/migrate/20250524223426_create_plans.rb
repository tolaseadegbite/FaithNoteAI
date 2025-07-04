class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :paystack_plan_code, null: false
      t.integer :amount, null: false
      t.string :interval, null: false
      t.string :currency, null: false
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :plans, :paystack_plan_code, unique: true
    add_index :plans, :active
  end
end