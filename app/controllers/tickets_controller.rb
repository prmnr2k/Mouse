class TicketsController < ApplicationController
  before_action :auth_creator_and_set_event
  before_action :set_ticket, only: [:show, :update, :destroy]

  swagger_controller :tickets, "Tickets"

  # GET events/1/tickets/1
  swagger_api :show do
    summary "Event's ticket"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Ticket id"
    param :query, :account_id, :integer, :required, "Creator id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def show
    render json: @ticket, status: :ok
  end

  # POST events/1/tickets
  swagger_api :create do
    summary "Creates ticket for event"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Creator id"
    param :form, :name, :string, :required, "Ticket name"
    param :form, :description, :string, :optional, "Ticket description"
    param :form, :price, :integer, :required, "Ticket price"
    param :form, :count, :integer, :required, "Ticket count"
    param_list :form, :type, :string, :required, "Ticket type", ["in_person", "vr"]
    param_list :form, :category, :string, :optional, "Ticket category", ["regular", "gold", "gold_vip"]
    param :form, :is_special, :boolean, :required, "If ticket is special"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def create
    @ticket = Ticket.new(ticket_params)
    set_type
    set_category

    if @ticket.save
      render json: @ticket, status: :created
    else
      render json: @ticket.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT events/1/tickets/1
  swagger_api :update do
    summary "Update event's ticket"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Ticket id"
    param :form, :account_id, :integer, :required, "Creator id"
    param :form, :name, :string, :required, "Ticket name"
    param :form, :description, :string, :optional, "Ticket description"
    param :form, :price, :integer, :required, "Ticket price"
    param :form, :count, :integer, :required, "Ticket count"
    param_list :form, :type, :string, :required, "Ticket type", ["in_person", "vr"]
    param_list :form, :category, :string, :optional, "Ticket category", ["regular", "gold", "gold_vip"]
    param :form, :is_special, :boolean, :required, "If ticket is special"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def update
    if @ticket.update(ticket_params)
      set_type
      set_category

      render json: @ticket, status: :ok
    else
      render json: @ticket.errors, status: :unprocessable_entity
    end
  end

  # DELETE events/1/tickets/1
  swagger_api :destroy do
    summary "Delete event's ticket"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Ticket id"
    param :form, :account_id, :integer, :required, "Creator id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
    response :forbidden
  end
  def destroy
    if not @ticket.fan_tickets
      @ticket.destroy
      render status: :ok
    else
      render status: :forbidden
    end
  end

  private
    def set_ticket
      @ticket = @event.tickets.find(params[:id])
    end

    def set_type
      if @ticket.tickets_type
        @ticket_type = @ticket.tickets_type
        @ticket_type.update(name: params[:type])
      else
        obj = TicketsType.new(name: params[:type])
        obj.save

        @ticket.tickets_type = obj
      end
    end

    def set_category
      if params[:category]
        if @ticket.tickets_category
          @ticket_category = @ticket.tickets_category
          @ticket_category.update(name: params[:category])
        else
          obj = TicketsCategory.new(name: params[:category])
          obj.save

          @ticket.tickets_category = obj
        end
      end
    end

    def ticket_params
      params.permit(:name, :price, :count, :is_special, :event_id)
    end

    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user
    end

    def auth_creator_and_set_event
      authorize_account
      @event = Event.find(params[:event_id])
      @creator = @event.creator
      render status: :unauthorized if @creator != @account or @creator.user != @user
    end
end
