class AddStatusCheckConstraintToSubscriptions < ActiveRecord::Migration[8.0]
  def up
    # Define the allowed enum values. Adjust these to match your enum definition exactly.
    allowed_statuses = [
      'active',
      'inactive',
      'pending',
      'non_renewing',
      'expired',
      'incomplete'
    ]

    # For PostgreSQL:
    execute <<-SQL
      ALTER TABLE subscriptions
      ADD CONSTRAINT status_check CHECK (status IN (#{allowed_statuses.map { |s| "'#{s}'" }.join(', ')}));
    SQL
  end

  def down
    # For PostgreSQL:
    execute <<-SQL
      ALTER TABLE subscriptions
      DROP CONSTRAINT IF EXISTS status_check;
    SQL
  end
end