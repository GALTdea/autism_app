require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get onboarding_show_url
    assert_response :success
  end

  test "should get update" do
    get onboarding_update_url
    assert_response :success
  end

  test "should get start" do
    get onboarding_start_url
    assert_response :success
  end
end
