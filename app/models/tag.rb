# == Schema Information
#
# Table name: tags
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
#  index_tags_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Tag < ApplicationRecord
  has_many :note_tags, dependent: :destroy
  has_many :notes, through: :note_tags
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :ordered, -> { order(id: :desc) }

  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end
end
