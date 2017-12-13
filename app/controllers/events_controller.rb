class EventsController < ApplicationController
  before_action :set_event, only: [:show, :update, :destroy]
  before_action :authorize_account, only: [:create]
  before_action :authorize_creator, only: [:update, :destroy]
  swagger_controller :accounts, "Accounts"

  # GET /events
  swagger_api :index do
    summary "Retrieve list of events"
    param :query, :limit, :integer, :required, "Limit"
    param :query, :offset, :integer, :required, "Offset"
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
    render json: @event, status: :ok
  end

  # POST /events
  swagger_api :create do
    summary 'Create event'
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :name, :string, :required, "Event name"
    param :form, :tagline, :string, :required, "Tagline"
    param :form, :description, :string, :required, "Short description"
    param :form, :funding_from, :datetime, :required, "Finding duration from"
    param :form, :funding_to, :datetime, :required, "Finding duration to"
    param :form, :funding_goal, :integer, :required, "Funding goal"
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
    summary 'Create event'
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :name, :string, :required, "Event name"
    param :form, :tagline, :string, :required, "Tagline"
    param :form, :description, :string, :required, "Short description"
    param :form, :funding_from, :datetime, :required, "Finding duration from"
    param :form, :funding_to, :datetime, :required, "Finding duration to"
    param :form, :funding_goal, :integer, :required, "Funding goal"
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
      render json: @event
    else
      render json: @event.errors, status: :unprocessable_entity
    end
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

    def event_params
      params.permit(:name, :tagline, :description, :funding_from, :funding_to, :funding_goal)
    end
end
