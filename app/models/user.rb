# == Schema Information
#
# Table name: users
#
#  id                             :bigint           not null, primary key
#  bible_chat_conversations_count :integer          default(0), not null
#  categories_count               :integer          default(0)
#  email_address                  :string           not null
#  name                           :string
#  notes_count                    :integer          default(0), not null
#  password_digest                :string           not null
#  paystack_customer_code         :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_users_on_email_address           (email_address) UNIQUE
#  index_users_on_paystack_customer_code  (paystack_customer_code)
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, presence: true, length: { minimum: 6 }

  def email
    email_address
  end

  has_many :notes, dependent: :destroy
  has_many :bible_chat_messages, dependent: :destroy
  has_many :bible_chat_conversations, dependent: :destroy

  has_many :categories, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  def active_subscription
    subscriptions.find_by(status: 'active')
  end

  def active_subscription?
    active_subscription.present? && 
    (active_subscription.expires_at.nil? || active_subscription.expires_at > Time.current) &&
    (active_subscription.next_payment_date.nil? || active_subscription.next_payment_date > Time.current)
  end

  def current_plan
    active_subscription&.plan
  end
end
