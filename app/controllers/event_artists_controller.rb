class EventArtistsController < ApplicationController
  before_action :set_event, only: [:create, :owner_accept, :owner_decline, :artist_accept, :artist_decline]
  before_action :authorize_creator, only: [:create, :owner_accept, :owner_decline]
  before_action :authorize_artist, only: [:artist_accept, :artist_decline]
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

  # POST /events/1/artist/1/owner_accept
  swagger_api :owner_accept do
    summary "Accept artist for event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Artist account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def owner_accept
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

  # POST /events/1/artist/1/owner_decline
  swagger_api :owner_decline do
    summary "Remove artist from event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Artist account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def owner_decline
    @artist_event = @event.artist_events.find_by(artist_id: params[:id])

    if @artist_event and not ["owner_accepted", "accepted"].include?(@artist_event.status)
      @artist_event.status = 'owner_declined'
      @artist_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/artist/1/artist_accept
  swagger_api :artist_accept do
    summary "Artist accepts request"
    param :path, :id, :integer, :required, "Artist id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :preferred_date_from, :datetime, :required, "Preferred date from"
    param :form, :preferred_date_to, :datetime, :required, "Preferred date to"
    param :form, :price, :integer, :required, "Price"
    param :form, :travel_price, :integer, :optional, "Travel price"
    param :form, :hotel_price, :integer, :optional, "Hotel price"
    param :form, :transportation_price, :integer, :optional, "Transportation price"
    param :form, :band_price, :integer, :optional, "Band price"
    param :form, :other_price, :integer, :optional, "Other price"
    param :header, 'Authorization', :string, :required, "Artist auth key"
  end
  def artist_accept
    @artist_acc = Account.find(params[:id])
    @artist_event = @event.artist_events.find_by(artist_id: @artist_acc.id)

    if @artist_event and ["pending", "request_send"].include?(@artist_event.status)
      @artist_event.status = 'accepted'
      send_approval(@artist_acc)
      @artist_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/artist/1/artist_decline
  def artist_decline

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

    def authorize_artist
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:id])
      render status: :unauthorized and return if @user == nil or @account.user != @user or @account.account_type != 'artist'
    end

    def send_mouse_request(account)
      request_message = RequestMessage.new(request_message_params)
      request_message.save

      inbox_message = InboxMessage.new(name: "#{@event.name} request", message_type: "request")
      inbox_message.request_message = request_message

      @event.request_messages << request_message
      @creator.inbox_messages << inbox_message
      account.inbox_messages << inbox_message
    end

    def send_approval(account)
      accept_message = AcceptMessage.new(accept_message_params)
      accept_message.save

      inbox_message = InboxMessage.new(name: "#{account.user_name} accepted #{@event.name} invitation", message_type: "accept")
      inbox_message.accept_message = accept_message

      @event.accept_messages << accept_message
      @event.creator.inbox_messages << inbox_message
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

    def accept_message_params
      params.permit(:preferred_date_from, :preferred_date_to, :price,
                    :travel_price, :hotel_price, :transportation_price, :band_price, :other_price)
    end

end