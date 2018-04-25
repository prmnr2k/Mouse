class FanTicketsController < ApplicationController
  before_action :authorize_account
  before_action :set_ticket, only: [:create]
  before_action :check_ticket, only: [:create]
  before_action :set_fan_ticket, only: [:show, :destroy]
  swagger_controller :fan_ticket, "FanTickets"

  # GET /fan_tickets
  swagger_api :index do
    summary "Retrieve list of fan tickets"
    param :query, :account_id, :integer, :required, "Fan account id"
    param_list :query, :time, :string, :required, "Tickets time frame", ['current', 'past']
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def index
    if params[:time] == 'current'
      @events = Event.joins(:tickets => :fan_tickets).where(
        fan_tickets: {account_id: params[:account_id]}
      ).where(
        "(events.date_from >= :date OR events.date_from IS NULL)", {:date => DateTime.now}
      ).group("events.id")
    else
      @events = Event.joins(:tickets => :fan_tickets).where(
        fan_tickets: {account_id: params[:account_id]}
      ).where(
        "(events.date_from < :date", {:date => DateTime.now}
      ).group("events.id")
    end
    render json: @events.limit(params[:limit]).offset(params[:offset]), fan_ticket: true, status: :ok
  end

  # GET /fan_tickets/by_event
  swagger_api :by_event do
    summary "Bought tickets by event"
    param :query, :account_id, :integer, :required, "Fan account id"
    param :query, :event_id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def by_event
    render json: {
      event: Event.find(params[:event_id]),
      tickets: FanTicket.joins(:ticket).where(account_id: params[:account_id], tickets: {event_id: params[:event_id]})
    }, fan_ticket: true, with_tickets: true, status: :ok
  end

  # GET /fan_tickets/1
  swagger_api :show do
    summary "Fan ticket info"
    param :path, :id, :integer, :required, "FanTicket id"
    param :query, :account_id, :integer, :required, "Fan account id"
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
    param :form, :account_id, :integer, :required, "Fan account id"
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
    param :form, :account_id, :integer, :required, "Fan account id"
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
      params.permit(:ticket_id, :account_id)
    end

    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user or @account.account_type != 'fan'
    end
end
