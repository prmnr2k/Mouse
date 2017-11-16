require 'test_helper'

class PhoneValidationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @phone_validation = phone_validations(:one)
  end

  test "should get index" do
    get phone_validations_url, as: :json
    assert_response :success
  end

  test "should create phone_validation" do
    assert_difference('PhoneValidation.count') do
      post phone_validations_url, params: { phone_validation: { is_validated: @phone_validation.is_validated, phone: @phone_validation.phone } }, as: :json
    end

    assert_response 201
  end

  test "should show phone_validation" do
    get phone_validation_url(@phone_validation), as: :json
    assert_response :success
  end

  test "should update phone_validation" do
    patch phone_validation_url(@phone_validation), params: { phone_validation: { is_validated: @phone_validation.is_validated, phone: @phone_validation.phone } }, as: :json
    assert_response 200
  end

  test "should destroy phone_validation" do
    assert_difference('PhoneValidation.count', -1) do
      delete phone_validation_url(@phone_validation), as: :json
    end

    assert_response 204
  end
end
