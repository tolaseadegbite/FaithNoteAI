# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  name        :string
#  notes_count :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_categories_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Category < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2 }
  belongs_to :user, counter_cache: :categories_count
  has_many :notes, dependent: :destroy

  scope :ordered, -> { order(id: :desc) }

  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["inventory"]
  end
end
