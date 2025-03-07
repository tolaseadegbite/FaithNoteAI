require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_path
    assert_response :success
  end

  test "should get pricing" do
    get pricing_path
    assert_response :success
  end

  test "should get privacy" do
    get privacy_path
    assert_response :success
  end

  test "should get documentation" do
    get documentation_path
    assert_response :success
  end
end
