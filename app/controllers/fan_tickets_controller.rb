class FanTicketsController < ApplicationController
  before_action :authorize_account
  before_action :set_ticket, only: [:create]
  before_action :check_ticket, only: [:create]
  before_action :set_fan_ticket, only: [:show, :destroy]
  swagger_controller :fan_ticket, "FanTickets"

  # GET /fan_tickets
  swagger_api :index do
    summary "Retrieve list of fan tickets"
    param :query, :fan_id, :integer, :required, "Fan id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def index
    @fan_tickets = FanTicket.all
    render json: @fan_tickets.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # GET /fan_tickets/1
  swagger_api :show do
    summary "Fan ticket info"
    param :path, :id, :integer, :required, "FanTicket id"
    param :query, :fan_id, :integer, :required, "Fan id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def show
    render json: @fan_ticket, status: :ok
  end

  # POST /fan_tickets
  swagger_api :create do
    summary "Buy ticket"
    param :form, :fan_id, :integer, :required, "Fan id"
    param :form, :ticket_id, :integer, :required, "Ticket id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :forbidden
  end
  def create
    @fan_ticket = FanTicket.new(fan_ticket_params)
    @fan_ticket.price = @ticket.price
    @fan_ticket.code = generate_auth_code

    if @fan_ticket.save
      render json: @fan_ticket, status: :created
    else
      render json: @fan_ticket.errors, status: :unprocessable_entity
    end
  end

  # DELETE /fan_tickets/1
  swagger_api :destroy do
    summary "Return ticket"
    param :path, :id, :integer, :required, "Ticket id"
    param :form, :fan_id, :integer, :required, "Fan id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
  end
  def destroy
    @fan_ticket.destroy
    render status: :ok
  end

  private
    def set_fan_ticket
      @fan_ticket = FanTicket.find(params[:id])
    end

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def check_ticket
      sold_tickets = FanTicket.where(ticket_id: @ticket.id)

      if sold_tickets and sold_tickets.count >= @ticket.count
        render status: :forbidden
      end
    end

    def generate_auth_code
      return '0000'
    end

    def fan_ticket_params
      params.permit(:ticket_id, :fan_id)
    end

    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:fan_id])
      render status: :unauthorized if @user == nil or @account.user != @user or @account.account_type != 'fan'
    end
end
