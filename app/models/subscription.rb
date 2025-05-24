# == Schema Information
#
# Table name: subscriptions
#
#  id                             :bigint           not null, primary key
#  amount                         :integer
#  authorization_code             :string
#  bank                           :string
#  card_type                      :string
#  currency                       :string
#  exp_month                      :string
#  exp_year                       :string
#  expires_at                     :datetime
#  interval                       :string
#  last_four_digits               :string
#  paid_at                        :datetime
#  paystack_customer_code         :string
#  paystack_plan_code             :string
#  paystack_subscription_code     :string
#  paystack_transaction_reference :string
#  plan_name                      :string
#  status                         :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  user_id                        :bigint           not null
#
# Indexes
#
#  index_subscriptions_on_authorization_code              (authorization_code)
#  index_subscriptions_on_paystack_customer_code          (paystack_customer_code)
#  index_subscriptions_on_paystack_subscription_code      (paystack_subscription_code) UNIQUE
#  index_subscriptions_on_paystack_transaction_reference  (paystack_transaction_reference)
#  index_subscriptions_on_status                          (status)
#  index_subscriptions_on_user_id                         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Subscription < ApplicationRecord
  enum status: {
    active: 'active',
    inactive: 'inactive', # Or 'cancelled', 'disabled'
    pending: 'pending',
    non_renewing: 'non_renewing',
    expired: 'expired',
    incomplete: 'incomplete' # For subscriptions that didn't complete payment
  }, _prefix: true # Optional: to call like subscription.status_active?

  validates :paystack_plan_code, presence: true
  validates :paystack_subscription_code, presence: true, uniqueness: true
  validates :status, presence: true
  validates :paystack_customer_code, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :plan_name, presence: true
  validates :interval, presence: true
  
  belongs_to :user
end
