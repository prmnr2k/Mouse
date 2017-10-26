require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
  end

  test "should get index" do
    get accounts_url, as: :json
    assert_response :success
  end

  test "should create account" do
    assert_difference('Account.count') do
      post accounts_url, params: { account: { account_type: @account.account_type, artist_id: @account.artist_id, fan_id: @account.fan_id, image_id: @account.image_id, phone: @account.phone, user_id: @account.user_id, venue_id: @account.venue_id } }, as: :json
    end

    assert_response 201
  end

  test "should show account" do
    get account_url(@account), as: :json
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account), params: { account: { account_type: @account.account_type, artist_id: @account.artist_id, fan_id: @account.fan_id, image_id: @account.image_id, phone: @account.phone, user_id: @account.user_id, venue_id: @account.venue_id } }, as: :json
    assert_response 200
  end

  test "should destroy account" do
    assert_difference('Account.count', -1) do
      delete account_url(@account), as: :json
    end

    assert_response 204
  end
end
