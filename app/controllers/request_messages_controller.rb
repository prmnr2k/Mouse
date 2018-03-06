class RequestMessagesController < ApplicationController
  before_action :authorize_account
  swagger_controller :request_messages, "Messages"

  # GET account/1/messages
  swagger_api :index do
    summary "Retrieve list of messages"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
  end
  def index
    @messages = RequestMessage.where(receiver_id: @account.id)

    render json: @messages.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # GET account/1/messages/1
  swagger_api :show do
    summary "Retrieve message"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :path, :id, :integer, :required, "Message id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
  end
  def show
    @message = RequestMessage.find(params[:id])

    render json: @message, extended: true, status: :ok
  end

  private
  def authorize_account
    @user = AuthorizeHelper.authorize(request)
    @account = Account.find(params[:account_id])
    render status: :unauthorized if @user == nil or @account.user != @user
  end
end