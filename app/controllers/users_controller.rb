class UsersController < ApplicationController
  before_action :authorize_me, only: [:update_me, :get_me]
  swagger_controller :users, "Users"

  # GET /users/me
  swagger_api :get_me do
    summary "Retrives User object of authorized user"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end

  def get_me
      render json: @user, serializer: UsersSerializer
  end

  # POST /users/create
  swagger_api :create do
    summary "Creates user credential for login"
    param :form, :first_name, :string, :required, "First name"
    param :form, :last_name, :string, :required, "Last name"
    param :form, :user_name, :string, :required, "Mouse username"
    param :form, :image_base64, :string, :required, "Image base64 string"
    param :form, :email, :string, :required, "Email"
    param :form, :password, :password, :required, "Your password"
    param :form, :password_confirmation, :password, :optional, "Confirm your password"
    param :form, :register_phone, :string, :optional, "Phone number"
    response :unprocessable_entity
  end

  def create
    if params[:register_phone]
      @phone_validation = PhoneValidation.find_by(phone: params[:register_phone])
      render json: {register_phone: [:NOT_VALIDATED]}, status: :unprocessable_entity and return if not @phone_validation or @phone_validation.is_validated == false
    end

    @user = User.new(user_create_params)
    if @user.save
      token = AuthenticateHelper.process_token(request, @user)
      user = @user.as_json
      user[:token] = token.token
      user.delete("password")

      set_base64_image
      render json: user,  serializer: UsersSerializer, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PUT /users/update/<id>
  def update
      if @user.update(user_update_params)
          render json: @user, serializer: UsersSerializer, status: :ok
      else
          render json: @user.errors, status: :unprocessable_entity
      end
  end

  # PUT /users/update_me
  swagger_api :update_me do
    summary "Update my user info"
    param :form, :first_name, :string, :required, "First name"
    param :form, :last_name, :string, :required, "Last name"
    param :form, :user_name, :string, :required, "Mouse username"
    param :form, :image_base64, :string, :required, "Image base64 string"
    param :form, :email, :string, :optional, "Email"
    param :form, :password, :password, :optional, "Your password"
    param :form, :password_confirmation, :password, :optional, "Confirm your password"
    param :form, :old_password, :password, :optional, "Old password"
    param :form, :register_phone, :string, :optional, "Phone number"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
  end

  def update_me
    if params[:register_phone]
      @phone_validation = PhoneValidation.find_by(phone: params[:register_phone])
      render json: {register_phone: [:NOT_VALIDATED]}, status: :unprocessable_entity and return if not @phone_validation or @phone_validation.is_validated == false
    end
    
    if @user.update(user_update_params)
      set_base64_image

      render json: @user, serializer: UsersSerializer, status: :ok
      else
          render json: @user.errors, status: :unprocessable_entity
      end
  end

  # DELETE /users/1
  swagger_api :destroy do
    summary "Delete user"
    param :query, :id, :integer, :required, "User id"
    response :not_found
  end

  def destroy
    @user.destroy

    render status: :ok
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def find_user
    @to_find = User.find(params[:id])
  end

  def check_access(access)
    return AuthorizeHelper.has_access?(@user, access)
  end

  def authorize
    @user = AuthorizeHelper.authorize(request)
    return @user != nil
  end

  def authorize_me
    render status: :forbidden if not authorize
  end

  def user_create_params
    params.permit(:email, :password, :password_confirmation, :register_phone, :first_name, :last_name, :user_name)
  end

  def user_update_params
    params.permit(:email, :password, :password_confirmation, :old_password,
                  :register_phone, :first_name, :last_name, :user_name)
  end

  def set_base64_image
    if params[:image_base64]
      image = Image.new(base64: params[:image_base64])
      image.save
      @user.image = image
      @user.save
    end
  end
end
