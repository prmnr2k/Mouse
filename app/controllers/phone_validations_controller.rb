class PhoneValidationsController < ApplicationController
  before_action :set_phone_validation, only: [:show, :update, :destroy]

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
    end

    # Only allow a trusted parameter "white list" through.
    def phone_validation_params
      params.permit(:phone)
    end
end
