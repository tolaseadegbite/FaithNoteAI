class AddBillingCycleDateToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :next_payment_date, :datetime
  end
end
