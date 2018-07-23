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
    ).left_joins(:tickets => :fan_tickets).order(:date_from => :desc).group("events.id")

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
    ).left_joins(:tickets => :fan_tickets).order(:date_from => :desc).group("events.id").find(params[:id])

    render json: event, serializer: AdminEventRevenueSerializer, status: :ok
  end

  # GET /admin/revenue/cities
  swagger_api :cities do
    summary "Get revenue by cities"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def cities
    cities = FanTicket.select(
      "fans.address, sum(fan_tickets.price) as price"
    ).joins(account: :fan).group("fans.address").order('price')
    render json: {
      total: FanTicket.sum(:price),
      cities: cities.as_json(only: [:address, :price])
    }, status: :ok
  end

  # GET /admin/revenue/counts
  swagger_api :counts do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def counts
    render json: {
      date: 0,
      artist: 0,
      venue: 0,
      vr: 0,
      tickets: 0,
      advertising: 0,
      crowdfung: 0,
      regular: 0
    }, status: :ok
  end

  # GET /admin/revenue/counts/date
  swagger_api :date do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def date
    render json: 0, status: :ok
  end

  # GET /admin/revenue/counts/artist
  swagger_api :artist do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def artist
    render json: 0, status: :ok
  end

  # GET /admin/revenue/venue
  swagger_api :venue do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def venue
    render json: 0, status: :ok
  end

  # GET /admin/revenue/counts/vr
  swagger_api :vr do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def vr
    render json: 0, status: :ok
  end

  # GET /admin/revenue/counts/tickets
  swagger_api :tickets do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def tickets
    render json: 0, status: :ok
  end

  # GET /admin/revenue/counts/advertising
  swagger_api :advertising do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def advertising
    render json: 0, status: :ok
  end

  # GET /admin/revenue/counts/funding
  swagger_api :funding do
    summary "Get revenue counts"
    param_list :query, :type, :string, :required, "Type of revenue", [:total, :sales]
    param_list :query, :funding_type, :string, :required, "Type of revenue", [:crowdfunding, :regular]
    param_list :query, :by, :string, :optional, "Data by", [:day, :week, :month, :year, :all]
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def funding
    render json: 0, status: :ok
  end

  private
  def authorize_admin
    user = AuthorizeHelper.authorize(request)

    render status: :unauthorized and return if user == nil or (user.is_superuser == false and user.is_admin == false)
    @admin = user.admin
  end
end