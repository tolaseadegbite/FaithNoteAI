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
#  next_payment_date              :datetime
#  paid_at                        :datetime
#  paystack_customer_code         :string
#  paystack_plan_code             :string
#  paystack_subscription_code     :string
#  paystack_transaction_reference :string
#  pending_plan_change_at         :datetime
#  pending_plan_change_type       :string
#  plan_name                      :string
#  status                         :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  pending_plan_id                :integer
#  plan_id                        :bigint           not null
#  user_id                        :bigint           not null
#
# Indexes
#
#  index_subscriptions_on_authorization_code              (authorization_code)
#  index_subscriptions_on_paystack_customer_code          (paystack_customer_code)
#  index_subscriptions_on_paystack_subscription_code      (paystack_subscription_code) UNIQUE
#  index_subscriptions_on_paystack_transaction_reference  (paystack_transaction_reference)
#  index_subscriptions_on_pending_plan_id                 (pending_plan_id)
#  index_subscriptions_on_plan_id                         (plan_id)
#  index_subscriptions_on_status                          (status)
#  index_subscriptions_on_user_id                         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (plan_id => plans.id)
#  fk_rails_...  (user_id => users.id)
#
class Subscription < ApplicationRecord
  enum :status, {
    active: 'active',
    inactive: 'inactive', 
    pending: 'pending',
    non_renewing: 'non_renewing',
    expired: 'expired',
    incomplete: 'incomplete'
  }, prefix: true # Ensure your enum definition is correct as per previous fixes

  validates :paystack_plan_code, presence: true
  validates :paystack_subscription_code, presence: true, uniqueness: true
  validates :status, presence: true
  validates :paystack_customer_code, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :plan_name, presence: true
  validates :interval, presence: true

  belongs_to :user
  belongs_to :plan

  def active?
    status == 'active'
  end
end
