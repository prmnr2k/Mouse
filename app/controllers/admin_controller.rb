class AdminController < ApplicationController

  # TODO: fix it
  before_action :authorize_admin, except: [:make_superuser, :statuses]
  swagger_controller :accounts, "Accounts"

  # GET /admin/new_accounts_count
  swagger_api :new_accounts_count do
    summary "Get number of new accounts in the system"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def new_accounts_count
    render json: {
      artist: Account.where(created_at: DateTime.now..1.month.ago, account_type: 'artist').count,
      fan: Account.where(created_at: DateTime.now..1.month.ago, account_type: 'fan').count,
      venue: Account.where(created_at: DateTime.now..1.month.ago, account_type: 'venue').count
    }, status: :ok
  end

  # POST /admin/make_superuser
  swagger_api :make_superuser do
    summary "Give user a superuser role"
    param :form, :user_id, :integer, :required, "Account id"
    # param :header, 'Authorization', :string, :required, 'Authentication token'
    # response :unauthorized
  end
  def make_superuser
    account = User.find(params[:user_id]).update(is_superuser: true)
    render json: account, status: :ok
  end

  # POST /admin/create_admin
  swagger_api :create_admin do
    summary "Creates admin credential for login"
    param :form, :image_base64, :string, :optional, "Image base64 string"
    param :form, :first_name, :string, :required, "First name"
    param :form, :last_name, :string, :required, "Last name"
    param :form, :user_name, :string, :required, "Mouse username"
    param :form, :email, :string, :required, "Email"
    param :form, :password, :password, :required, "Your password"
    param :form, :password_confirmation, :password, :required, "Confirm your password"
    param :form, :register_phone, :string, :required, "Phone number"
    param :form, :address, :string, :optional, "Address"
    param :form, :other_address, :string, :optional, "Other address"
    param :form, :city, :string, :optional, "City"
    param :form, :country, :string, :optional, "Country"
    param :form, :state, :string, :optional, "State"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end
  def create_admin
    @user = User.new(user_create_params)
    @user.is_admin = true
    if @user.save
      set_base64_image
      set_admin
      set_phone_validation

      token = AuthenticateHelper.process_token(request, @user)
      user = @user.as_json
      user[:token] = token.token
      user.delete("password")

      render json: user, except: :password, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # GET /admin/statuses
  swagger_api :statuses do
    summary "Retrieve statuses values"
  end
  def statuses
    render json: StatusHelper.admin_translations, status: :ok
  end

  # GET admin/accounts/requests
  swagger_api :account_requests do
    summary "Get all account requests"
    param_list :query, :account_type, :string, :required, 'Type of accounts', ['all', 'artist', 'fan', 'venue']
    param :query, :limit, :integer, :optional, 'Limit'
    param :query, :offset, :integer, :optional, 'Offset'
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def account_requests
    accounts = Account.all

    if params[:account_type] != 'all'
      accounts = accounts.where(account_type: params[:account_type])
    end
    render json: accounts.limit(params[:limit]).offset(params[:offset]),
           each_serializer: AdminAccountSerializer,
           status: :ok
  end

  # GET admin/accounts/<id>
  swagger_api :get_account do
    summary "Retrieve account by id"
    param :path, :id, :integer, :required, "Account id"
    param :header, 'Authorization', :string, :optional, 'Authentication token'
    response :not_found
  end
  def get_account
    render json: Account.find(params[:id]), extended: true, my: true, status: :ok
  end

  # GET admin/events/requests
  swagger_api :event_requests do
    summary "Get all event requests"
    param :query, :limit, :integer, :optional, 'Limit'
    param :query, :offset, :integer, :optional, 'Offset'
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def event_requests
    events = Event.all

    render json: events.limit(params[:limit]).offset(params[:offset]),
           each_serializer: AdminEventSerializer,
           status: :ok
  end

  # GET admin/events/1
  swagger_api :get_event do
    summary "Retrieve event by id"
    param :path, :id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
  end
  def get_event
    render json: Event.find(params[:id]), extended: true, status: :ok
  end


  private
  def authorize_admin
    user = AuthorizeHelper.authorize(request)
    render status: :unauthorized if user == nil or user.is_superuser == false or user.is_admin == false and return
  end

  def user_create_params
    params.permit(:email, :password, :password_confirmation, :register_phone)
  end

  def admin_create_params
    params.permit(:address, :other_address, :city, :state, :country, :first_name, :last_name, :user_name)
  end

  def set_admin
    admin = Admin.new(admin_create_params)
    admin.user_id = @user.id
    unless admin.save
      render json: admin.errors, status: :unprocessable_entity and return
    end
  end

  def set_base64_image
    if params[:image_base64]
      image = Image.new(base64: params[:image_base64])
      image.save
      @user.image = image
      @user.save
    end
  end

  def set_phone_validation
    phone_validation = PhoneValidation.new(phone: params[:register_phone])
    unless phone_validation.save
      render json: phone_validation.errors, status: :unprocessable_entity and return
    end
  end
end
