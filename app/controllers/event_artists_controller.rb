class EventArtistsController < ApplicationController
  before_action :set_event, only: [:create, :accept, :decline]
  before_action :authorize_creator, only: [:create, :accept, :decline]
  swagger_controller :event_artists, "Event artists"

  # POST /events/1/artist
  swagger_api :create do
    summary "Add artist to event"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :artist_id, :integer, :required, "Artist account id"
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
    if artist_available?
      @event.artists << @artist_acc
      send_mouse_request(@artist_acc)
      @event.save

      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue/1/accept
  swagger_api :accept do
    summary "Accept artist for event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Artist account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def accept
    # if @event.venue_id == nil
    #   @venue_event = @event.venue_events.find_by(venue_id: params[:venue_id])
    #
    #   if @venue_event and @venue_event.status == 'active'
    #     @venue_event.status = 'accepted'
    #     @venue_event.save
    #
    #     change_event
    #     render status: :ok
    #   else
    #     render status: :not_found
    #   end
    # else
    #   render status: :unprocessable_entity
    # end
  end

  # POST /events/1/artist
  swagger_api :decline do
    summary "Remove artist from event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Artist account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def decline
    @artist_event = @event.artist_events.find_by(artist_id: params[:id])

    if @artist_event and @artist_event.status != 'owner_accepted'
      @artist_event.status = 'owner_declined'
      # change_event_back
      @artist_event.save

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


  def artist_available?
    @artist_acc = Account.find(params[:artist_id])
    if @artist_acc and @artist_acc.account_type == 'artist' and
      @event.artist_events.where.not(status: 'declined').count < @event.artists_number
      return true
    end

    return false
  end

    def request_message_params
      params.permit(:time_frame, :is_personal, :estimated_price, :message)
    end

end