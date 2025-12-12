require "test_helper"

class ActivityLogsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get activity_logs_create_url
    assert_response :success
  end

  test "should get index" do
    get activity_logs_index_url
    assert_response :success
  end
end
