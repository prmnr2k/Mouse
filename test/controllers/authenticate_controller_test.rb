require 'test_helper'

class AuthenticateControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @password = "123123"
  end

  test "should authenticate by login" do
    post "/auth/login", params: {user_name: @user.user_name, password: @password}, as: :json
    assert_response :success
  end

  test "should authenticate by email" do
    post "/auth/login", params: {email: @user.email, password: @password}, as: :json
    assert_response :success
  end

  test "should logout" do
    post "/auth/login", params: {email: @user.email, password: @password}

    response_body = JSON.parse(@response.body)
    post "/auth/logout", headers: {Authorization: response_body["token"]}
    assert_response :success
  end
end
