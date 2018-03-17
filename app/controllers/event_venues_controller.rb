class EventVenuesController < ApplicationController
  before_action :set_event, only: [:create, :accept, :decline]
  before_action :authorize_creator, only: [:create, :accept, :decline]
  swagger_controller :event_venues, "Event venues"

  # POST /events/1/venue
  swagger_api :create do
    summary "Add venue to event"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :venue_id, :integer, :required, "Venue account id"
    param_list :form, :time_frame, :integer, :required, "Time frame to answer", ["two_hours", "two_days", "one_week"]
    param :form, :is_personal, :boolean, :optional, "Is message personal"
    param :form, :estimated_price, :integer, :optional, "Estimated price to perform"
    param :form, :message, :string, :optional, "Additional text"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def create
    if venue_available?
      @event.venues << @venue_acc
      send_mouse_request(@venue_acc)
      @event.save

      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue/1/accept
  swagger_api :accept do
    summary "Accept venue for event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Venue account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def accept
    if @event.venue_id == nil
      @venue_event = @event.venue_events.find_by(venue_id: params[:venue_id])

      if @venue_event and @venue_event.status == 'active'
        @venue_event.status = 'accepted'
        @venue_event.save

        change_event
        render status: :ok
      else
        render status: :not_found
      end
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue/1/decline
  swagger_api :decline do
    summary "Decline venue for event"
    param :path, :id, :integer, :required, "Venue account id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def decline
    @venue_event = @event.venue_events.find_by(venue_id: params[:id])

    if @venue_event and @venue_event.status != 'owner_accepted'
      @venue_event.status = 'owner_declined'
      change_event_back
      @venue_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  private
  def set_event
    @event = Event.find(params[:event_id])
  end

  def authorize_creator
    @user = AuthorizeHelper.authorize(request)
    @account = Account.find(params[:account_id])
    render status: :unauthorized and return if @user == nil or @account.user != @user

    @creator = Event.find(params[:event_id]).creator
    render status: :unauthorized if @creator != @account or @creator.user != @user
  end

  def send_mouse_request(account)
    request_message = RequestMessage.new(request_message_params)
    request_message.save

    inbox_message = InboxMessage.new(name: "#{@event.name} request", message_type: "request")
    inbox_message.request_message = request_message

    @event.inbox_messages << inbox_message
    account.inbox_messages << inbox_message
  end

  def request_message_params
    params.permit(:time_frame, :is_personal, :estimated_price, :message)
  end

  def venue_available?
    @venue_acc = Account.find(params[:venue_id])

    if @venue_acc and @venue_acc.account_type == 'venue' and
      @event.venue_events.where.not(status: 'declined').count < Rails.configuration.number_of_venues
      return true
    end

    return false
  end

  def change_event
    @venue_acc = @venue_event.account

    # save to rollback
    @event.old_address = @event.address
    @event.old_city_lat = @event.city_lat
    @event.old_city_lng = @event.city_lng

    @event.address = @venue_acc.venue.address
    @event.city_lat = @venue_acc.venue.lat
    @event.city_lng = @venue_acc.venue.lng
    @event.venue_id = @venue_acc.id
    @event.save!
  end

  def change_event_back
    @event.address = @event.old_address
    @event.city_lat = @event.old_city_lat
    @event.city_lng = @event.old_city_lng
    @event.venue_id = nil

    @event.save!
  end
end