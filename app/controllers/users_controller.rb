class UsersController < ApplicationController
  before_action :authorize_me, only: [:update_me, :get_me]  
  before_action :find_user, only: [:validate_phone]  

  # GET /users/get_me
  def get_me
      render json: @user, except: :password
  end

  # POST /users/create
  def create
      @user = User.new(user_create_params)
      @user.is_phone_validated = false
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

  # POST /users/validated_phone
  def validate_phone
      if params[:code] == '000000'
          @to_find.is_phone_validated = true
          @to_find.save(validate: false)
          render json: @to_find, status: :ok
      else
          render json: {code: [:INVALID]}, status: :unprocessable_entity
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
