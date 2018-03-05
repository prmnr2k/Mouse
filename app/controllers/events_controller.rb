class EventsController < ApplicationController
  before_action :set_event, only: [:show, :update, :destroy, :set_artist, :set_venue, :set_active,
                                   :like, :unlike, :analytics, :click, :view, :delete_venue, :delete_artist,
                                   :get_updates, :accept_venue, :decline_venue, :get_likes]
  before_action :authorize_fan, only: [:create]
  before_action :authorize_account, only: [:my]
  before_action :authorize_creator, only: [:update, :destroy, :set_artist, :set_venue, :delete_artist,
                                           :delete_venue, :set_active, :accept_venue, :decline_venue, :get_likes]
  before_action :authorize_user, only: [:like, :unlike]
  swagger_controller :events, "Events"

  # GET /events
  swagger_api :index do
    summary "Retrieve list of events"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    response :ok
  end
  def index
    @events = Event.where(is_active: true)

    render json: @events.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # GET /events/1
  swagger_api :show do
    summary "Retrieve event by id"
    param :path, :id, :integer, :required, "Event id"
    response :ok
  end
  def show  
    render json: @event, extended: true, status: :ok
  end

  # GET /events/1/updates
  swagger_api :get_updates do
    summary "Retrieve event updates by id"
    param :path, :id, :integer, :required, "Event id"
    response :ok
  end
  def get_updates
    event_updates = @event.event_updates.select(:action, :field, :created_at).as_json.each {|e| e[:type] = "event"}
    venue_updates = @event.venue.account_updates.select(
      :action, :field, :created_at).as_json.each {|e| e[:type] = "venue"}

    artists_ids = @event.artist_events.where(status: 'accepted').pluck(:artist_id)
    artists_updates = AccountUpdate.where(account_id: artists_ids).select(
      :action, :field, :created_at).as_json.each {|e| e[:type] = "artist"}

    event_updates.concat(artists_updates).concat(venue_updates).sort_by{|u| u[:created_at]}

    render json: event_updates
  end

  # POST /events
  swagger_api :create do
    summary 'Create event'
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :name, :string, :optional, "Event name"
    param :form, :image_base64, :string, :optional, "Image base64 string"
    param :form, :image, :file, :optional, "Image"
    param :form, :tagline, :string, :optional, "Tagline"
    param :form, :description, :string, :optional, "Short description"
    param :form, :funding_from, :datetime, :optional, "Finding duration from"
    param :form, :funding_to, :datetime, :optional, "Finding duration to"
    param :form, :funding_goal, :integer, :optional, "Funding goal"
    param :form, :updates_available, :boolean, :optional, "Is updates available"
    param :form, :comments_available, :boolean, :optional, "Is comments available"
    param :form, :date_from, :datetime, :optional, "Date from"
    param :form, :date_to, :datetime, :optional, "Date to"
    param :form, :event_month, :integer, :optional, "Event month range. One of ['jan', 'feb', 'mar', 'apr', 'may', 'jun',
                                                      'jul', 'aug', 'sep', 'oct', 'nov', 'dec']"
    param :form, :event_year, :integer, :optional, "Event year range"
    param :form, :event_length, :integer, :optional, "Event length in hours"
    param :form, :event_time, :integer, :optional, "Event time. One of ['morning', 'afternoon', 'evening']"
    param :form, :is_crowdfunding_event, :boolean, :optional, "Is crowdfunding event"
    param :form, :city_lat, :float, :optional, "Event city lat"
    param :form, :city_lng, :float, :optional, "Event city lng"
    param :form, :address, :string, :optional, "Event address"
    param :form, :artists_number, :integer, :optional, "Event artists number"
    param :form, :genres, :string, :optional, "Genres list ['pop', 'rock', ...]"
    param :form, :collaborators, :string, :optional, "Collaborators list [1,2,3, ...]"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end
  def create
    @event = Event.new(event_params)
    @event.creator = @account

    if @event.save
      set_image
      set_base64_image
      set_genres
      set_collaborators

      render json: @event, status: :created
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /events/1
  swagger_api :update do
    summary 'Update event'
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :image_base64, :string, :optional, "Image base64 string"
    param :form, :image, :file, :optional, "Image"
    param :form, :name, :string, :optional, "Event name"
    param :form, :date, :datetime, :optional, "Event date"
    param :form, :tagline, :string, :optional, "Tagline"
    param :form, :description, :string, :optional, "Short description"
    param :form, :funding_from, :datetime, :optional, "Finding duration from"
    param :form, :funding_to, :datetime, :optional, "Finding duration to"
    param :form, :funding_goal, :integer, :optional, "Funding goal"
    param :form, :updates_available, :boolean, :optional, "Is updates available"
    param :form, :comments_available, :boolean, :optional, "Is comments available"
    param :form, :date_from, :datetime, :optional, "Date from"
    param :form, :date_to, :datetime, :optional, "Date to"
    param :form, :event_month, :integer, :optional, "Event month range. One of ['jan', 'feb', 'mar', 'apr', 'may', 'jun',
                                                      'jul', 'aug', 'sep', 'oct', 'nov', 'dec']"
    param :form, :event_year, :integer, :optional, "Event year range"
    param :form, :event_length, :integer, :optional, "Event length in hours"
    param :form, :event_time, :integer, :optional, "Event time. One of ['morning', 'afternoon', 'evening']"
    param :form, :is_crowdfunding_event, :boolean, :optional, "Is crowdfunding event"
    param :form, :city_lat, :float, :optional, "Event city lat"
    param :form, :city_lng, :float, :optional, "Event city lng"
    param :form, :address, :string, :optional, "Event address"
    param :form, :artists_number, :integer, :optional, "Event artists number"
    param :form, :genres, :string, :optional, "Genres list ['pop', 'rock', ...]"
    param :form, :collaborators, :string, :optional, "Collaborators list [1,2,3, ...]"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end
  def update
    set_image
    set_base64_image
    set_genres
    set_collaborators

    forbidden = check_params
    if not forbidden and @event.update(event_params)

      log_update
      render json: @event, extended: true, status: :ok
    else
      render json: @event.errors, status: (forbidden ? forbidden : :unprocessable_entity)
    end
  end

  # GET /event/1/analytics
  swagger_api :analytics do
    summary "Get analytic data"
    param :path, :id, :integer, :required, "Event id"
    response :unauthorized
    response :not_found
  end
  def analytics
    render json: @event, analytics: true, status: :ok
  end

  # POST /events/1/artist
  swagger_api :set_artist do
    summary "Add artist to event"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :artist_id, :integer, :required, "Artist account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def set_artist
    if artist_available?
      @event.artists << @artist_acc
      @event.save
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # DELETE /events/1/artist
  swagger_api :delete_artist do
    summary "Remove artist from event"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :artist_id, :integer, :required, "Artist account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def delete_artist
    @artist_acc = Account.find(params[:artist_id])

    if @artist_acc and @artist_acc.account_type == 'artist'
      @event.artists.delete(@artist_acc)
      # @event.save
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue
  swagger_api :set_venue do
    summary "Add venue to event"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :venue_id, :integer, :required, "Venue account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def set_venue
    if venue_available?
      @event.venues << @venue_acc
      @event.save
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue/1/accept
  swagger_api :accept_venue do
    summary "Accept venue for event"
    param :path, :id, :integer, :required, "Event id"
    param :path, :venue_id, :integer, :required, "Venue account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def accept_venue
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
  swagger_api :decline_venue do
    summary "Decline venue for event"
    param :path, :id, :integer, :required, "Event id"
    param :path, :venue_id, :integer, :required, "Venue account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def decline_venue
    if @event.venue_id != nil
      @venue_event = @event.venue_events.find_by(venue_id: params[:venue_id])

      if @venue_event and @venue_event.status == 'accepted'
        @venue_event.status = 'active'
        @venue_event.save

        change_event_back
        render status: :ok
      else
        render status: :not_found
      end
    else
      render status: :unprocessable_entity
    end
  end

  # DELETE /events/1/venue
  swagger_api :delete_venue do
    summary "Remove venue from event"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :venue_id, :integer, :required, "Venue account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def delete_venue
    @venue_acc = Account.find(params[:venue_id])

    if @venue_acc and @venue_acc.account_type == 'venue' and @event.venue_id != nil
      @event.venues.delete(@venue_acc)
      # @event.save
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/activate
  swagger_api :set_active do
    summary "Set event active"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def set_active
    @event.is_active = true
    @event.save

    render status: :ok
  end

  # POST /events/1/like
  swagger_api :like do
    summary "Like event"
    param :path, :id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def like
    obj = Like.new(event_id: @event.id, user_id: @user.id)
    obj.save

    render status: :ok
  end

  # POST /events/1/unlike
  swagger_api :unlike do
    summary "Unlike event"
    param :path, :id, :integer, :required, "Event id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def unlike
    obj = Like.find_by(event_id: @event, user_id: @user)
    if not obj
      render status: :not_found
    else
      obj.destroy
      render status: :ok
    end
  end

  # POST /events/1/get_likes
  swagger_api :get_likes do
    summary "Retrieve list of accounts liked"
    param :path, :id, :integer, :required, "Event id"
    param :query, :account_id, :integer, :required, "Authorized account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :not_found
  end
  def get_likes
    @accounts = Account.joins(:user => :likes).where(likes: {event_id: @event}).group('user_id').order('accounts.account_type DESC')

    render json: @accounts.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # GET /events/1/click
  swagger_api :click do
    summary "Add click to event"
    param :path, :id, :integer, :required, "Event id"
    response :not_found
  end
  def click
    @event.clicks += 1
    @event.save

    render status: :ok
  end

  # GET /events/1/view
  swagger_api :view do
    summary "Add view to event"
    param :path, :id, :integer, :required, "Event id"
    response :not_found
  end
  def view
    @event.views += 1
    @event.save

    render status: :ok
  end

  # GET /events/my
  swagger_api :my do
    summary "Get my events"
    param :query, :account_id, :integer, :required, "Account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    param :header, 'Authorization', :string, :required, "Auth token"
    response :unauthorized
  end
  def my
    @events = Event.all

    if @account.account_type == 'fan'
      @events = @events.where(creator: params[:account_id])
    elsif @account.account_type == 'artist'
      @events = @events.joins(:artist_events).where(
        :artist_events => {artist_id: params[:account_id], status: 'accepted'})
    elsif @account.account_type == 'venue'
      @events = @events.where(venue_id: params[:account_id])
    end


    render json: @events.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  # DELETE /events/1
  swagger_api :destroy do
    summary "Destroy event by id"
    param :path, :id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def destroy
    @event.destroy
    render status: :ok
  end

  # GET /events/search
  swagger_api :search do
    summary "Search for event"
    param :query, :text, :string, :optional, "Text to search"
    param :query, :location, :string, :optional, "Address"
    param :query, :lat, :float, :optional, "Latitude (lng and distance must be present)"
    param :query, :lng, :float, :optional, "Longitude (lat and distance must be present)"
    param :query, :distance, :float, :optional, "Radius in km (lat, lng must be present)"
    param :query, :from_date, :datetime, :optional, "Left bound of date (to_date must be presenty)"
    param :query, :to_date, :datetime, :optional, "Right bound of date (from_date must be present)"
    param :query, :is_active, :boolean, :optional, "Search only active events (do not send it for All option)"
    param :query, :genres, :string, :optional, "Genres list ['pop', 'rock', ...]"
    param :query, :ticket_types, :string, :optional, "Ticket types ['in_person', 'vip']"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    response :ok
  end
  def search
    @events = Event.search(params[:text])
    search_status
    search_genre
    search_location
    search_distance
    search_ticket_types
    search_date

    render json: @events.distinct.limit(params[:limit]).offset(params[:offset]), status: :ok
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    #TODO: отрефакторить как-нибудь
    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user
    end

    def authorize_fan
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized and return if @user == nil or @account.user != @user

      render status: :unauthorized if @account.account_type != 'fan'
    end

    def authorize_creator
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized and return if @user == nil or @account.user != @user

      @creator = Event.find(params[:id]).creator
      render status: :unauthorized if @creator != @account or @creator.user != @user
    end

    def set_image
      if params[:image]
        image = Image.new(base64: Base64.encode64(File.read(params[:image].path)))
        @event.image = image
        @event.images << image
      end
    end

    def set_base64_image
      if params[:image_base64]
        image = Image.new(base64: params[:image_base64])
        @event.image = image
        @event.images << image
      end
    end

    def set_genres
      if params[:genres]
        @event.genres.clear
        params[:genres].each do |genre|
          obj = EventGenre.new(genre: genre)
          obj.save
          @event.genres << obj
        end
      end
    end

    def set_collaborators
      if params[:collaborators]
        @event.collaborators.clear
        params[:collaborators].each do |collaborator|
          obj = Account.find(collaborator)
          @event.collaborators << obj
        end
      end
    end

    def search_status
      if params[:is_active]
        @events = @events.where(is_active: params[:is_active])
      end
    end

    def search_date
       if params[:from_date] and params[:to_date]
         @events = @events.where(date: DateTime.parse(params[:from_date])..DateTime.parse(params[:to_date]))
       end
    end

    def search_location
      if params[:location]
        @events = @events.near(params[:location])
      end
    end

    def search_distance
      if params[:distance] and params[:lng] and params[:lat]
        @events = @events.near([params[:lat], params[:lng]], params[:distance])
      end
    end

    def search_genre
      if params[:genres]
        genres = []
        params[:genres].each do |genre|
          genres.append(EventGenre.genres[genre])
        end
        @events = @events.joins(:genres).where(:event_genres => {genre: genres})
      end
    end

    def search_ticket_types
      if params[:ticket_types]
        types = []
        params[:ticket_types].each do |type|
          types.append(TicketsType.names[type])
        end
        @events = @events.joins(:tickets => :tickets_type).where(:tickets_types => {name: types})
      end
    end

    def artist_available?
      @artist_acc = Account.find(params[:artist_id])
      number = @event.artists_number != nil ? @event.artists_number : 0
      if @artist_acc and @artist_acc.account_type == 'artist' and
            @event.artist_events.where.not(status: 'declined').count < number
        return true
      end

      return false
    end

    def venue_available?
      @venue_acc = Account.find(params[:venue_id])

      if @venue_acc and @venue_acc.account_type == 'venue' and
            @event.venue_events.where.not(status: 'declined').count < Rails.configuration.number_of_venues
        return true
      end

      return false
    end

    def log_update
      params.each do |param|
        if HistoryHelper::EVENT_FIELDS.include?(param.to_sym)
          action = EventUpdate.new(action: :update, updated_by: @account.id, event_id: @event.id, field: param)
          action.save
        end
      end
    end

  def check_params
    if params[:date_from] or params[:date_to]
      founded = @event.tickets.joins(:fan_tickets).sum("fan_tickets.price")

      return :forbidden if founded >= @event.funding_goal
    end

    if (params[:address] or params[:city_lat] or params[:city_lng]) and @event.venue_id != nil
      return :forbidden
    end
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

    def event_params
      params.permit(:name, :tagline, :description, :funding_from, :funding_to,
                    :funding_goal, :comments_available, :updates_available, :date_from, :date_to,
                    :event_month, :event_year, :event_length, :event_time, :is_crowdfunding_event,
                    :city_lat, :city_lng, :address, :artists_number)
    end

    def authorize
      @user = AuthorizeHelper.authorize(request)
      return @user != nil
    end

    def authorize_user
      render status: :forbidden if not authorize
    end
end
