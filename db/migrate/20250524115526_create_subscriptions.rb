class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :paystack_plan_code
      t.string :paystack_subscription_code
      t.string :status
      t.datetime :expires_at
      t.string :paystack_customer_code
      t.string :plan_name
      t.string :interval
      t.integer :amount
      t.string :currency

      t.timestamps
    end

    add_index :subscriptions, :paystack_subscription_code, unique: true
    add_index :subscriptions, :paystack_customer_code
    add_index :subscriptions, :status
  end
end