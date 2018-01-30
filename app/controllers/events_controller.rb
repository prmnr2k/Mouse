class EventsController < ApplicationController
  before_action :set_event, only: [:show, :update, :destroy, :set_artist, :set_venue, :set_active,
                                   :like, :unlike, :analytics, :click, :view]
  before_action :authorize_account, only: [:create, :my_events]
  before_action :authorize_creator, only: [:update, :destroy, :set_artist, :set_venue, :set_active]
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
    @events = Event.all

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

  # POST /events
  swagger_api :create do
    summary 'Create event'
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :name, :string, :optional, "Event name"
    param :form, :date, :datetime, :optional, "Event date"
    param :form, :tagline, :string, :optional, "Tagline"
    param :form, :description, :string, :optional, "Short description"
    param :form, :funding_from, :datetime, :optional, "Finding duration from"
    param :form, :funding_to, :datetime, :optional, "Finding duration to"
    param :form, :funding_goal, :integer, :optional, "Funding goal"
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
    param :form, :name, :string, :optional, "Event name"
    param :form, :date, :datetime, :optional, "Event date"
    param :form, :tagline, :string, :optional, "Tagline"
    param :form, :description, :string, :optional, "Short description"
    param :form, :funding_from, :datetime, :optional, "Finding duration from"
    param :form, :funding_to, :datetime, :optional, "Finding duration to"
    param :form, :funding_goal, :integer, :optional, "Funding goal"
    param :form, :genres, :string, :optional, "Genres list ['pop', 'rock', ...]"
    param :form, :collaborators, :string, :optional, "Collaborators list [1,2,3, ...]"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end
  def update
    set_genres
    set_collaborators

    if @event.update(event_params)
      render json: @event, extended: true, status: :ok
    else
      render json: @event.errors, status: :unprocessable_entity
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
    @artist_acc = Account.find(params[:artist_id])
    if @artist_acc
      if @artist_acc.account_type == 'artist'
        @event.artist = @artist_acc.artist
        @event.save
        render status: :ok
      else
        render status: :unprocessable_entity
      end
    else
      render status: :not_found
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
    @venue_acc = Account.find(params[:venue_id])
    if @venue_acc
      if @venue_acc.account_type == 'venue'
        @event.venue = @venue_acc.venue
        @event.save
        render status: :ok
      else
        render status: :unprocessable_entity
      end
    else
      render status: :not_found
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

    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user
    end

    def authorize_creator
      authorize_account
      @creator = Event.find(params[:id]).creator
      render status: :unauthorized if @creator != @account or @creator.user != @user
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
        venues = Venue.near(params[:location]).select{|v| v.id}
        @events = @events.where(venue_id: venues)
      end
    end

    def search_distance
      if params[:distance] and params[:lng] and params[:lat]
        venues = Venue.near([params[:lat], params[:lng]], params[:distance]).select{|v| v.id} 
        @events = @events.where(venue_id: venues)
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

    def event_params
      params.permit(:name, :tagline, :description, :funding_from, :funding_to, :funding_goal, :date)
    end

    def authorize
      @user = AuthorizeHelper.authorize(request)
      return @user != nil
    end

    def authorize_user
      render status: :forbidden if not authorize
    end
end
