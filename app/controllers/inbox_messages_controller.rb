class InboxMessagesController < ApplicationController
  before_action :authorize_account
  before_action :set_message, only: [:show, :destroy, :change_responce_time]
  swagger_controller :inbox_messages, "Inbox messages"

  # GET account/1/inbox_messages
  swagger_api :index do
    summary "Retrieve list of inbox messages"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
  end
  def index
    @messages = InboxMessage.where(receiver_id: @account.id)

    render json: @messages.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # GET account/1/inbox_messages/1
  swagger_api :show do
    summary "Retrieve message"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :path, :id, :integer, :required, "Message id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
    response :not_found
    response :unauthorized
  end
  def show
    if @message.receiver_id == params[:account_id]
      render json: @message, extended: true, status: :ok
    else
      render status: :not_found
    end
  end

  # GET account/1/inbox_messages/my
  swagger_api :my do
    summary "Retrieve message"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
    response :not_found
    response :unauthorized
  end
  def my
    @messages = InboxMessage.joins(:event).where(:events => {creator_id: params[:account_id]})

    render json: @messages.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # POST account/1/inbox_messages/1/change_responce_time
  swagger_api :change_responce_time do
    summary "Change message's time to responce"
    param :path, :account_id, :integer, :required, "Authorized account id"
    param :path, :id, :integer, :required, "Message id"
    param_list :form, :time_frame, :integer, :required, "Time frame to answer", ["two_hours", "two_days", "one_week"]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
    response :not_found
    response :unauthorized
  end
  def change_responce_time
    if @message.event.creator_id == params[:account_id].to_i
      @message.request_message.time_frame = params[:time_frame]
      @message.save!

      render json: @message, extended: true, status: :ok
    else
      render status: :not_found
    end
  end

  # DELETE account/1/inbox_messages/1
  def destroy
    @message.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = InboxMessage.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def inbox_params
      params.permit(:receiver_id, :event_id)
    end

    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user
    end
end
