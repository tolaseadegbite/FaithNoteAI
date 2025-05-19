# == Schema Information
#
# Table name: users
#
#  id                             :bigint           not null, primary key
#  bible_chat_conversations_count :integer          default(0), not null
#  categories_count               :integer          default(0)
#  email_address                  :string           not null
#  notes_count                    :integer          default(0), not null
#  password_digest                :string           not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email_address: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email_address should be present" do
    @user.email_address = "     "
    assert_not @user.valid?
  end

  test "email_address should not be too long" do
    @user.email_address = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  test "email_address validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email_address = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test "email_address validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com foo@bar..com]
    invalid_addresses.each do |invalid_address|
      @user.email_address = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email_address should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email_address = @user.email_address.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email_address should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email_address = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email_address
  end

  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end
end
