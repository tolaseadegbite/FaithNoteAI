class AddDetailsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :paystack_transaction_reference, :string
    add_column :subscriptions, :authorization_code, :string
    add_column :subscriptions, :card_type, :string
    add_column :subscriptions, :last_four_digits, :string
    add_column :subscriptions, :exp_month, :string
    add_column :subscriptions, :exp_year, :string
    add_column :subscriptions, :bank, :string
    add_column :subscriptions, :paid_at, :datetime

    # Optional: Add indexes if you anticipate querying by these fields frequently
    add_index :subscriptions, :paystack_transaction_reference
    add_index :subscriptions, :authorization_code
  end
end