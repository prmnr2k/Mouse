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
    param :form, :account_id, :integer, :required, "Account id"
    # param :header, 'Authorization', :string, :required, 'Authentication token'
    # response :unauthorized
  end
  def make_superuser
    account = Account.find(params[:account_id]).update(is_superuser: true)
    render json: account, status: :ok
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
    render status: :unauthorized if user == nil or user.is_superuser == false and return
  end
end
