class UsersController < ApplicationController
  before_action :authorize_me, only: [:update_me, :get_me]  

  # GET /users/get_me
  def get_me
      render json: @user, except: :password
  end

  # POST /users/create
  def create
      @phone_validation = PhoneValidation.find_by(phone: params[:register_phone])
      render json: {register_phone: [:NOT_VALIDATED]}, status: :unprocessable_entity and return if not @phone_validation or @phone_validation.is_validated == false
      
      @user = User.new(user_create_params)
      if @user.save
          render json: @user, except: :password, status: :created
      else
          render json: @user.errors, status: :unprocessable_entity
      end
  end

  # PUT /users/update/<id>
  def update
      if @user.update(user_update_params)
          render json: @user, except: :password, status: :ok
      else
          render json: @user.errors, status: :unprocessable_entity
      end
  end

  # PUT /users/update_me
  def update_me
      if @user.update(user_update_params)
          render json: @user, except: :password, status: :ok
      else
          render json: @user.errors, status: :unprocessable_entity
      end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
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
        params.permit(:email, :password, :password_confirmation, :register_phone)
    end

    def user_update_params
        params.permit(:email, :password, :password_confirmation, :old_password)
    end


end
