class PhoneValidationsController < ApplicationController
  before_action :set_phone_validation, only: [:show, :update, :destroy]
  swagger_controller :phone, "Phone validation"

  # GET /phone_validations
  def index
    @phone_validations = PhoneValidation.all

    render json: @phone_validations
  end

  # GET /phone_validations/1
  def show
    render json: @phone_validation
  end

  # POST /phone_validations
  swagger_api :create do
    summary "Request code for validation"
    param :form, :phone, :string, :required, "Phone number"
    response :unprocessable_entity
  end
  def create
    @phone_validation = PhoneValidation.find_by(phone: params[:phone])
    @phone_validation = PhoneValidation.new(phone_validation_params)  if not @phone_validation

    @phone_validation.code = '0000'
    @phone_validation.is_validated = false
    if @phone_validation.save
      render json: @phone_validation, except: :code, status: :created
    else
      render json: @phone_validation.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /phone_validations/1
  swagger_api :update do
    summary "Send validation code from SMS"
    param :form, :phone, :string, :required, "Phone number"
    param :query, :code, :string, :required, "Code"
    response :unprocessable_entity
  end
  def update
      if params[:code] == @phone_validation.code
          @phone_validation.is_validated = true
          @phone_validation.save
          render json: @phone_validation, except: :code, status: :ok
      else
          render json: {code: [:INVALID]}, status: :unprocessable_entity
      end
  end



  # DELETE /phone_validations/1
  def destroy
    @phone_validation.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone_validation
      @phone_validation = PhoneValidation.find_by(phone: params[:phone])
      render status: :not_found if not @phone_validation
    end

    # Only allow a trusted parameter "white list" through.
    def phone_validation_params
      params.permit(:phone)
    end
end
