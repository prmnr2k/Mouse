class AdminRevenueController < ApplicationController
  before_action :authorize_admin
  swagger_controller :admin_revenue, "AdminPanel"

  # GET /admin/revenue
  swagger_api :index do
    summary "Get revenue by event"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :ok
  end
  def index
    events = Event.select(
      "events.*, sum(fan_tickets.price) as revenue"
    ).left_joins(:tickets => :fan_tickets).group("events.id")

    render json: events.limit(params[:limit]).offset(params[:offset]),
           each_serializer: AdminEventsRevenueSerializer, status: :ok
  end

  # GET /admin/revenue/1
  swagger_api :show do
    summary "Get revenue by particular event"
    param :path, :id, :integer, :required, "Id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def show
    event = Event.select(
      "events.*, sum(fan_tickets.price) as total_revenue"
    ).left_joins(:tickets => :fan_tickets).group("events.id").find(params[:id])

    render json: event, serializer: AdminEventRevenueSerializer, status: :ok
  end

  private
  def authorize_admin
    user = AuthorizeHelper.authorize(request)

    render status: :unauthorized and return if user == nil or (user.is_superuser == false and user.is_admin == false)
    @admin = user.admin
  end
end