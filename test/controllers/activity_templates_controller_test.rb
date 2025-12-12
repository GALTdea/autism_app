require "test_helper"

class ActivityTemplatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get activity_templates_index_url
    assert_response :success
  end

  test "should get show" do
    get activity_templates_show_url
    assert_response :success
  end
end
