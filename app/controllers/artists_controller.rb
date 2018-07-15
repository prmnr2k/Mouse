class ArtistsController < ApplicationController
  before_action :authorize_user, only: [:create]
  before_action :authorize_account, only: [:update]
  after_action :log_artist_updates, only: [:update]
  swagger_controller :artists, "Artists"

  # POST /accounts
  swagger_api :create do
    summary "Creates new artist"
    param :form, :user_name, :string, :required, "Artist's name"
    param :form, :display_name, :string, :optional, "Artist's name to display"
    param :form, :phone, :string, :optional, "Artist's phone"
    param :form, :first_name, :string, :optional, "Artist first name"
    param :form, :last_name, :string, :optional, "Artist last name"
    param :form, :about, :string, :optional, "About artist"
    param :form, :stage_name, :string, :optional, "Artist stage name"
    param :form, :manager_name, :string, :optional, "Artist's manager name"
    param :form, :artist_email, :string, :optional, "Artist's email"
    param :form, :genres, :string, :optional, "Artist genres ['genre1', 'genre2', ...]"
    param :form, :performance_min_time, :integer, :optional, "Artist min time to perform (hr)"
    param :form, :performance_max_time, :integer, :optional, "Artist max time to perform (hr)"
    param :form, :price_from, :integer, :optional, "Artist min price to perform"
    param :form, :price_to, :integer, :optional, "Artist max time to perform"
    param :form, :additional_hours_price, :integer, :optional, "Artist price for additional hours"
    param :form, :is_hide_pricing_from_profile, :boolean, :optional, "Hide artist pricing from profile?"
    param :form, :is_hide_pricing_from_search, :boolean, :optional, "Hide artist pricing from search?"
    param :form, :days_to_travel, :integer, :optional, "Artist days to travel"
    param :form, :can_perform_without_band, :boolean, :optional, "Can artist perform without band?"
    param :form, :preferred_address, :string, :optional, "Artist preferred address to perform"
    param :form, :lat, :float, :optional, "Artist lat"
    param :form, :lng, :float, :optional, "Artist lng"
    param :form, :is_perform_with_band, :boolean, :optional, "Is artist perform with band?"
    param :form, :is_perform_with_backing_vocals, :boolean, :optional, "Is artist perform with backing vocals?"
    param :form, :can_perform_without_backing_vocals, :boolean, :optional, "Can artist perform without backing vocals?"
    param :form, :is_permitted_to_stream, :boolean, :optional, "Is artist give permission to stream?"
    param :form, :is_permitted_to_advertisement, :boolean, :optional, "Is artist give permission to advertisement?"
    param :form, :has_conflict_contracts, :boolean, :optional, "Has artist conflict contracts to advertisement?"
    param :form, :conflict_companies_names, :string, :optional, "Names of artist's conflict companies"
    param :form, :preferred_venue_text, :string, :optional, "Artist other preferred venue types"
    param :form, :min_time_to_book, :integer, :optional, "Artist min time to book"
    param :form, :min_time_to_free_cancel, :integer, :optional, "Artist min time to cancel"
    param :form, :late_cancellation_fee, :integer, :optional, "Artist late cancellation fee"
    param :form, :refund_policy, :string, :optional, "Artist refund policy"
    param :form, :preferred_venues, :string, :optional, "Array of preferred venue types"
    param :form, :facebook, :string, :optional, "Artist facebook username"
    param :form, :twitter, :string, :optional, "Artist twitter username"
    param :form, :instagram, :string, :optional, "Artist instagram username"
    param :form, :snapchat, :string, :optional, "Artist snapchat username"
    param :form, :spotify, :string, :optional, "Artist spotify username"
    param :form, :soundcloud, :string, :optional, "Artist soundcloud username"
    param :form, :youtube, :string, :optional, "Artist youtube username"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end

  def create
    Artist.transaction do
      @artist = Artist.new(artist_params)
      @artist.user = @user

      if @artist.save
        set_artist_genres
        set_artist_preferred_venues

        render json: @artist, extended: true, my: true, except: :password, status: :created
      else
        render json: @artist.errors, status: :unprocessable_entity
      end
    end
  end


  # PUT /accounts/<account_id>
  swagger_api :update do
    summary "Updates existing artist"
    param :path, :id, :integer, :required, "Artist id"
    param :form, :user_name, :string, :required, "Artist's name"
    param :form, :display_name, :string, :optional, "Artist's name to display"
    param :form, :phone, :string, :optional, "Artist's phone"
    param :form, :first_name, :string, :optional, "Artist first name"
    param :form, :last_name, :string, :optional, "Artist last name"
    param :form, :about, :string, :optional, "About artist"
    param :form, :stage_name, :string, :optional, "Artist stage name"
    param :form, :manager_name, :string, :optional, "Artist's manager name"
    param :form, :artist_email, :string, :optional, "Artist's email"
    param :form, :genres, :string, :optional, "Artist genres ['genre1', 'genre2', ...]"
    param :form, :performance_min_time, :integer, :optional, "Artist min time to perform (hr)"
    param :form, :performance_max_time, :integer, :optional, "Artist max time to perform (hr)"
    param :form, :price_from, :integer, :optional, "Artist min price to perform"
    param :form, :price_to, :integer, :optional, "Artist max time to perform"
    param :form, :additional_hours_price, :integer, :optional, "Artist price for additional hours"
    param :form, :is_hide_pricing_from_profile, :boolean, :optional, "Hide artist pricing from profile?"
    param :form, :is_hide_pricing_from_search, :boolean, :optional, "Hide artist pricing from search?"
    param :form, :days_to_travel, :integer, :optional, "Artist days to travel"
    param :form, :can_perform_without_band, :boolean, :optional, "Can artist perform without band?"
    param :form, :preferred_address, :string, :optional, "Artist preferred address to perform"
    param :form, :lat, :float, :optional, "Artist lat"
    param :form, :lng, :float, :optional, "Artist lng"
    param :form, :is_perform_with_band, :boolean, :optional, "Is artist perform with band?"
    param :form, :is_perform_with_backing_vocals, :boolean, :optional, "Is artist perform with backing vocals?"
    param :form, :can_perform_without_backing_vocals, :boolean, :optional, "Can artist perform without backing vocals?"
    param :form, :is_permitted_to_stream, :boolean, :optional, "Is artist give permission to stream?"
    param :form, :is_permitted_to_advertisement, :boolean, :optional, "Is artist give permission to advertisement?"
    param :form, :has_conflict_contracts, :boolean, :optional, "Has artist conflict contracts to advertisement?"
    param :form, :conflict_companies_names, :string, :optional, "Names of artist's conflict companies"
    param :form, :preferred_venue_text, :string, :optional, "Artist other preferred venue types"
    param :form, :min_time_to_book, :integer, :optional, "Artist min time to book"
    param :form, :min_time_to_free_cancel, :integer, :optional, "Artist min time to cancel"
    param :form, :late_cancellation_fee, :integer, :optional, "Artist late cancellation fee"
    param :form, :refund_policy, :string, :optional, "Artist refund policy"
    param :form, :preferred_venues, :string, :optional, "Array of preferred venue types"
    param :form, :facebook, :string, :optional, "Artist facebook username"
    param :form, :twitter, :string, :optional, "Artist twitter username"
    param :form, :instagram, :string, :optional, "Artist instagram username"
    param :form, :snapchat, :string, :optional, "Artist snapchat username"
    param :form, :spotify, :string, :optional, "Artist spotify username"
    param :form, :soundcloud, :string, :optional, "Artist soundcloud username"
    param :form, :youtube, :string, :optional, "Artist youtube username"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end

  def update
    Artist.transaction do
      if @artist.update(artist_params)
        set_artist_genres
        set_artist_preferred_venues

        render json: @artist, extended: true, my: true, except: :password, status: :ok
      else
        render json: @artist.errors, status: :unprocessable_entity
      end
    end
  end

  private
  def authorize_user
    @user = AuthenticateHelper.authorize_and_get_user(request)

    if @user == nil
      render status: :unauthorized and return
    end
  end

  def authorize_account
    @artist = AuthenticateHelper.authorize_and_get_account(request, params[:id]).specific
    if @artist == nil
      render status: :unauthorized and return
    end
  end

  def log_artist_updates
    params.each do |param|
      if HistoryHelper::ARTIST_FIELDS.include?(param.to_sym)
        action = AccountUpdate.new(action: :update, updated_by: @account.id, account_id: @account.id, field: param)
        action.save
      end
    end
  end

  def set_artist_genres
    if params[:genres]
      @artist.genres.clear
      params[:genres].each do |genre|
        obj = ArtistGenre.new(genre: genre)
        obj.save
        @artist.genres << obj
      end

      @artist.save
    end
  end

  def set_artist_preferred_venues
    if params[:preferred_venues]
      @artist.artist_preferred_venues.clear
      params[:preferred_venues].each do |venue_type|
        obj = ArtistPreferredVenue.new(type_of_venue: venue_type)
        obj.save
        @artist.artist_preferred_venues << obj
      end

      @artist.save
    end
  end

  def artist_params
    params.permit(:user_name, :display_name, :phone, :about, :lat, :lng, :preferred_address,
                  :first_name, :last_name, :stage_name, :manager_name, :facebook, :twitter,
                  :instagram, :snapchat, :spotify, :soundcloud, :youtube, :performance_min_time,
                  :performance_max_time, :price_from, :price_to, :additional_hours_price,
                  :is_hide_pricing_from_profile, :is_hide_pricing_from_search, :days_to_travel,
                  :is_perform_with_band, :can_perform_without_band, :is_perform_with_backing_vocals,
                  :can_perform_without_backing_vocals, :is_permitted_to_stream, :is_permitted_to_advertisement,
                  :has_conflict_contracts, :conflict_companies_names, :preferred_venue_text,
                  :min_time_to_book, :min_time_to_free_cancel, :late_cancellation_fee, :refund_policy, :artist_email)
  end
end
