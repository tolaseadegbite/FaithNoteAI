class AddPendingPlanFieldsToSubscriptions < ActiveRecord::Migration[7.1] # Or your Rails version
  def change
    add_column :subscriptions, :pending_plan_id, :integer
    add_column :subscriptions, :pending_plan_change_type, :string
    add_column :subscriptions, :pending_plan_change_at, :datetime

    # Optional: Add an index if you plan to query by pending_plan_id frequently
    add_index :subscriptions, :pending_plan_id
  end
end