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
require "test_helper"

class PlanTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
