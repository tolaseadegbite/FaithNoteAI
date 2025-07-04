# == Schema Information
#
# Table name: plans
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(FALSE), not null
#  amount             :integer          not null
#  currency           :string           not null
#  description        :text             not null
#  interval           :string           not null
#  name               :string           not null
#  paystack_plan_code :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_plans_on_active              (active)
#  index_plans_on_paystack_plan_code  (paystack_plan_code) UNIQUE
#
class Plan < ApplicationRecord
  has_many :subscriptions

  validates :name, presence: true
  validates :paystack_plan_code, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :interval, presence: true, inclusion: { in: %w[monthly yearly Monthly Yearly Annually annually], message: "%{value} is not a valid interval" }
  validates :description, presence: true
  # active is a boolean, presence is implicitly handled by default value and not_null constraint

  scope :active, -> { where(active: true) }

  def monthly?
    interval.downcase == 'monthly'
  end

  def yearly?
    interval.downcase == 'yearly' || interval.downcase == 'annually'
  end
end
