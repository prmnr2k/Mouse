class AdminEventsController < ApplicationController
  before_action :authorize_admin
  swagger_controller :admin, "AdminPanel"

  # GET /admin/accounts/new_count
  swagger_api :new_count do
    summary "Get number of new events added"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def new_count
    render json: Event.where(status: 'just_added').count, status: :ok
  end

  # GET admin/events/requests
  swagger_api :event_requests do
    summary "Get all event requests"
    param :query, :text, :string, :optional, "Search text"
    param_list :query, :event_type, :string, :optional, "Type of events", [:all, :crowdfunding, :regular]
    param_list :query, :status, :string, :optional, "Event status", [:just_added, :pending, :approved, :denied, :active, :inactive]
    param :query, :limit, :integer, :optional, 'Limit'
    param :query, :offset, :integer, :optional, 'Offset'
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def event_requests
    events = Event.all.order(:created_at)

    if params[:text]
      events = events.where("events.name ILIKE :query", query: "%#{params[:text]}%")
    end

    if params[:event_type] == 'crowdfunding'
      events = events.where(is_crowdfunding_event: true)
    elsif params[:event_type] == 'regular'
      events = events.where(is_crowdfunding_event: false)
    end

    if params[:status]
      events = events.where(status: params[:status])
    end

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

  # POST admin/events/<id>/approve
  swagger_api :approve do
    summary "Approve event"
    param :path, :id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
    response :method_not_allowed
  end
  def approve
    event = Event.find(params[:id])

    if event and ['pending', 'denied'].include?(event.status)
      event.update(status: 'approved')
      render status: :ok
    else
      render status: :method_not_allowed
    end
  end

  # POST admin/events/<id>/approve
  swagger_api :deny do
    summary "Deny event"
    param :path, :id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
    response :method_not_allowed
  end
  def deny
    event = Event.find(params[:id])

    if event and ['pending', 'approved'].include?(event.status)
      event.update(status: 'denied', denier_id: @admin.id)
      render status: :ok
    else
      render status: :method_not_allowed
    end
  end

  # DELETE admin/accounts/<id>
  swagger_api :destroy do
    summary "Delete account"
    param :path, :id, :integer, :required, "Account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :ok
  end
  def destroy
    event = Event.find(params[:id])
    event.destroy

    render status: :ok
  end

  private
  def authorize_admin
    user = AuthorizeHelper.authorize(request)

    render status: :unauthorized and return if user == nil or (user.is_superuser == false and user.is_admin == false)
    @admin = user.admin
  end
end