class AccountsController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:update,  :upload_image, :follow, :unfollow, :is_followed,
                                             :follow_multiple, :delete]
    before_action :find_account, only: [:get, :get_images, :upcoming_shows, :get_events, :get_followers, :get_followed, :get_updates, :verify]
    before_action :find_follower_account, only: [:follow, :unfollow, :is_followed]
    swagger_controller :accounts, "Accounts"


    # GET /accounts/<id>
    swagger_api :get do
      summary "Retrieve account by id"
      param :path, :id, :integer, :required, "Account id"
      param :query, :extended, :boolean, :optional, "Need extended info"
      param :header, 'Authorization', :string, :optional, 'Authentication token'
      response :not_found
    end
    def get
        @extended = true
        set_extended
        render json: @to_find, extended: @extended, my: authorized?, status: :ok
    end

    # GET /account/1/updates
    swagger_api :get_updates do
        summary "Retrieve account updates by id"
        param :path, :id, :integer, :required, "Account id"
        response :ok
    end
    def get_updates  
        render json: @to_find.account_updates
    end

    # GET /accounts/
    swagger_api :get_all do
      summary "Retrieve list of accounts"
      param :query, :extended, :boolean, :optional, "Need extended info"
      param :query, :limit, :integer, :optional, "Limit"
      param :query, :offset, :integer, :optional, "Offset"
      response :ok
    end
    def get_all
        @accounts = Account.all
        @extended = false
        set_extended
        render json: @accounts.order(:id).limit(params[:limit]).offset(params[:offset]), extended: @extended, status: :ok
    end

    # GET /accounts/events/1
    swagger_api :get_events do
      summary "Retrieve list of account events"
      param :path, :id, :integer, :required, "Account id"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      param :query, :text, :string, :optional, "Text to search"
      param :query, :limit, :integer, :optional, "Limit"
      param :query, :offset, :integer, :optional, "Offset"
    end
    def get_events
       @events = @to_find.events
       @events = @events.simple_search(params[:text])
       render json: @events.order(:id).limit(params[:limit]).offset(params[:offset])
    end

    # GET /accounts/my
    swagger_api :get_my_accounts do
      summary "Retrieve list of my accounts"
      param :query, :extended, :boolean, :optional, "Need extended info"
      param :header, 'Authorization', :string, :required, 'Authentication token'
    end
    def get_my_accounts   
       @extended = false
       set_extended
       render json: @user.accounts, extended: @extended, status: :ok
    end

    # GET /accounts/images/<id>
    swagger_api :get_images do
      summary "Retrieve list of images"
      param :path, :id, :integer, :required, "Account id"
      param :query, :limit, :integer, :optional, "Limit"
      param :query, :offset, :integer, :optional, "Offset"
      response :not_found
    end
    def get_images
        render json: {
            total_count: @to_find.images.count,
            images: @to_find.images.limit(params[:limit]).offset(params[:offset])
        }, image_only: true, status: :ok
    end

    # GET /accounts/<id>/upcoming_shows
    swagger_api :upcoming_shows do
      summary "Get upcoming shows"
      param :path, :id, :integer, :required, "Account id"
      param :query, :limit, :integer, :optional, "Limit"
      param :query, :offset, :integer, :optional, "Offset"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :not_found
      response :unprocessable_entity
    end
    def upcoming_shows
      events = Event.all

      if @to_find.account_type == 'artist'
        events = events.joins(:artist_events)
                   .where(artist_events: {artist_id: @to_find.id})
                   .where(artist_events: {status: ArtistEvent.statuses['active']})
                   .where("events.date_from >= :date", {:date => DateTime.now})

        render json: events.limit(params[:limit]).offset(params[:offset]), status: :ok
      elsif @to_find.account_type == 'venue'
        events = events.joins(:venue_events)
                   .where(venue_events: {venue_id: @to_find.id})
                   .where(venue_events: {status: VenueEvent.statuses['active']})
                   .where("events.date_from >= :date", {:date => DateTime.now})
        render json: events.limit(params[:limit]).offset(params[:offset]), status: :ok
      else
        render status: :unprocessable_entity
      end
    end

    #POST /accounts/images/<account_id>
    swagger_api :upload_image do
      summary "Upload image to Account"
      param :path, :id, :integer, :required, "Account id"
      param :form, :image, :file, :optional, "Image to upload"
      param :form, :image_base64, :string, :optional, "Image base64 string"
      param :form, :image_description, :string, :optional, "Image description"
      param_list :form, :image_type, :string, :optional, "Image type", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                        "stadium_arena", "outdoor_space", "other"]
      param :form, :image_type_description, :string, :optional, "Image other type description"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :unauthorized
      response :not_found
    end
    def upload_image
        set_image
        set_base64_image
        render json: @account, status: :ok
    end

    #GET /accounts/is_followed/<follower_id>
    swagger_api :is_followed do
      summary "Is followed"
      param :path, :id, :integer, :required, "My account id"
      param :query, :follower_id, :integer, :required, "Account id to check"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :not_found
      response :unauthorized
    end
    def is_followed
        follower = Follower.find_by(by_id: @account.id, to_id: @to_find.id)
        render json: {status: (follower != nil)}
    end


    #POST /accounts/follow/<account_id>
    swagger_api :follow do
      summary "Subscribe for account"
      param :path, :id, :integer, :required, "My account id"
      param :query, :follower_id, :integer, :required, "Following account id"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :not_found
      response :unauthorized
    end
    def follow
        follower = Follower.find_by(by_id: @account.id, to_id: @to_find.id)
        if not follower
            follower = Follower.new(by: @account, to: @to_find)  
            if follower.save
                render status: :ok
            else
                render json: follower.errors, status: :unprocessable_entity
            end
        end
    end

    #POST /accounts/follow
    swagger_api :follow_multiple do
      summary "Subscribe for accounts"
      param :path, :id, :integer, :required, "My account id"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      param :form, :follow, :string, :required, "Accounts ids, array: [1, 2, 3 ...]"
      response :unprocessable_entity
      response :not_found
      response :unauthorized
    end
    def follow_multiple
        params[:follow].each do |acc|
            follower = Follower.find_by(by_id: @account.id, to_id: acc)
            if not follower
                follower = Follower.new(by: @account, to_id: acc)  
                if not follower.save
                    render json: follower.errors, status: :unprocessable_entity
                    return
                end
            end
        end
        render status: :ok
    end

    # GET /accounts/followers/<id>
    swagger_api :get_followers do
      summary "Retrieve list of followers"
      param :path, :id, :integer, :required, "Account id"
      param :query, :offset, :integer, :optional, "Offset"
      param :query, :limit, :integer, :optional, "Limit"
      response :not_found
    end
    def get_followers 
        render json: {
            total_count: @to_find.followers.count,
            followers: @to_find.followers.order(:id).limit(params[:limit]).offset(params[:offset])
        }
    end

    # GET /accounts/following/<id>
    swagger_api :get_followed do
      summary "Retrieve list of following by me"
      param :path, :id, :integer, :required, "Account id"
      param :query, :offset, :integer, :optional, "Offset"
      param :query, :limit, :integer, :optional, "Limit"
      response :not_found
    end
    def get_followed
        render json: {
            total_count: @to_find.following.count,
            following: @to_find.following.order(:id).limit(params[:limit]).offset(params[:offset])
        }
    end

    #DELETE /accounts/unfollow/<account_id>
    swagger_api :unfollow do
      summary "Unubscribe from account"
      param :path, :id, :integer, :required, "My account id"
      param :query, :follower_id, :integer, :required, "Following account id"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :not_found
      response :unauthorized
      response :no_content
    end
    def unfollow
        follower = Follower.find_by(by_id: @account.id, to_id: @to_find.id)
        if follower 
            follower.destroy
            render status: :ok
        end
    end

    # POST /accounts
    swagger_api :create do
      summary "Creates new account"
      param :form, :user_name, :string, :required, "Account's name"
      param :form, :display_name, :string, :optional, "Account's name to display"
      param :form, :phone, :string, :optional, "Account's phone"
      param :form, :image_base64, :string, :optional, "Image base64 string"
      param :form, :image_description, :string, :optional, "Image description"
      param_list :form, :image_type, :string, :optional, "Image type", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                        "stadium_arena", "outdoor_space", "other"]
      param :form, :image_type_description, :string, :optional, "Image other type description"
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :venue_video_links, :string, :optional, "Array of links"
      param :form, :artist_videos, :string, :optional, "Array of link objects [{'name': '', 'album_name': '', 'link': ''}, {...}]"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :genres, :string, :optional, "Fan/Artist/Venue (public only) Genres ['genre1', 'genre2', ...]"
      param :form, :address, :string, :optional, "Fan/Venue address"
      param :form, :preferred_address, :string, :optional, "Artist preferred address to perform"
      param :form, :lat, :float, :optional, "Fan/Artist/Venue lat"
      param :form, :lng, :float, :optional, "Fan/Artist/Venue lng"
      param :form, :first_name, :string, :optional, "Fan/Artist first name"
      param :form, :last_name, :string, :optional, "Fan/Artist last name"
      param :form, :description, :string, :optional, "Venue description"
      param :form, :fax, :string, :optional, "Venue fax (public_venue only)"
      param :form, :bank_name, :string, :optional, "Venue bank name (public_venue only)"
      param :form, :account_bank_number, :string, :optional, "Venue account bank number (public_venue only)"
      param :form, :account_bank_routing_number, :string, :optional, "Venue account routing number (public_venue only)"
      param :form, :capacity, :integer, :optional, "Venue capacity"
      param :form, :num_of_bathrooms, :integer, :optional, "Venue num of bathrooms (public_venue only)"
      param :form, :min_age, :integer, :optional, "Venue min age (public_venue only)"
      param_list :form, :venue_type, :string, :optional, "Venue type", ["public_venue", "private_residence"]
      param_list :form, :type_of_space, :string, :optional, "Venue type of space (public_venue only)", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                                     "stadium_arena", "outdoor_space", "other"]
      param :form, :other_genre_description, :string, :optional, "Venue other genre description (for public venue if genre other)"
      param :form, :has_bar, :boolean, :optional, "Has venue bar? (public_venue only)"
      param_list :form, :located, :string, :optional, "Venue located (public_venue only)", ["indoors", "outdoors", "both"]
      param :form, :dress_code, :string, :optional, "Venue dress code (public_venue only)"
      param :form, :has_vr, :boolean, :optional, "Has venue vr?"
      param :form, :audio_description, :string, :optional, "Venue audio description (public_venue only)"
      param :form, :lighting_description, :string, :optional, "Venue lighting description (public_venue only)"
      param :form, :stage_description, :string, :optional, "Venue stage description (public_venue only)"
      param :form, :dates, :string, :optional, "Venue dates [{'begin_date': '', 'end_date': '', 'is_available': '',
                                                            'price': '', 'booking_notice': 'same_day|one_day|two_seven_days'}, {...}]"
      param :form, :emails, :string, :optional, "Venue dates [{'name': '', 'email': ''}, {...}]"
      param :form, :office_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :operating_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :price, :integer, :optional, "Venue (public only) price"
      param :form, :country, :string, :optional, "Venue (public only) country"
      param :form, :city, :string, :optional, "Venue (public only) city"
      param :form, :state, :string, :optional, "Venue (public only) state"
      param :form, :zipcode, :integer, :optional, "Venue (public only) zipcode"
      param :form, :minimum_notice, :integer, :optional, "Venue (public only) minimum notice time"
      param :form, :is_flexible, :boolean, :optional, "Is venue (public only) time flexible"
      param :form, :price_for_daytime, :integer, :optional, "Venue (public only) price for daytime"
      param :form, :price_for_nighttime, :integer, :optional, "Venue (public only) price for nighttime"
      param :form, :performance_time_from, :time, :optional, "Venue (public only) performance time from"
      param :form, :performance_time_to, :time, :optional, "Venue (public only) performance time to"
      param :form, :vr_capacity, :integer, :optional, "Venue vr tickets available"
      param :form, :about, :string, :optional, "About artist"
      param :form, :stage_name, :string, :optional, "Artist stage name"
      param :form, :manager_name, :string, :optional, "Artist'smanager name"
      param :form, :artist_email, :string, :optional, "Artist's email"
      param :form, :audio_links, :string, :optional, "Array of links to audio of artist [{'song_name': '', 'album_name': '', 'audio_link': ''}, {...}]"
      param :form, :artist_albums, :string, :optional, "Array of artist albums objects [{'album_name': '', 'album_artwork': '', 'album_link': ''}, {...}]"
      param :form, :available_dates, :string, :optional, "Artist available dates [{'begin_date': '', 'end_date': ''}, {...}]"
      param :form, :performance_min_time, :integer, :optional, "Artist min time to perform (hr)"
      param :form, :performance_max_time, :integer, :optional, "Artist max time to perform (hr)"
      param :form, :price_from, :integer, :optional, "Artist min price to perform"
      param :form, :price_to, :integer, :optional, "Artist max time to perform"
      param :form, :additional_hours_price, :integer, :optional, "Artist price for additional hours"
      param :form, :is_hide_pricing_from_profile, :boolean, :optional, "Hide artist pricing from profile?"
      param :form, :is_hide_pricing_from_search, :boolean, :optional, "Hide artist pricing from search?"
      param :form, :days_to_travel, :integer, :optional, "Artist days to travel"
      param :form, :is_perform_with_band, :boolean, :optional, "Is artist perform with band?"
      param :form, :can_perform_without_band, :boolean, :optional, "Can artist perform without band?"
      param :form, :is_perform_with_backing_vocals,:boolean, :optional, "Is artist perform with backing vocals?"
      param :form, :can_perform_without_backing_vocals, :boolean, :optional, "Can artist perform without backing vocals?"
      param :form, :is_permitted_to_stream, :boolean, :optional, "Is artist give permission to stream?"
      param :form, :is_permitted_to_advertisement,:boolean, :optional, "Is artist give permission to advertisement?"
      param :form, :has_conflict_contracts, :boolean, :optional, "Has artist conflict contracts to advertisement?"
      param :form, :conflict_companies_names, :string, :optional, "Names of artist's conflict companies"
      param :form, :preferred_venue_text,:string, :optional, "Artist other preferred venue types"
      param :form, :min_time_to_book, :integer, :optional, "Artist min time to book"
      param :form, :min_time_to_free_cancel, :integer, :optional, "Artist min time to cancel"
      param :form, :late_cancellation_fee, :integer, :optional, "Artist late cancellation fee"
      param :form, :refund_policy, :string, :optional, "Artist refund policy"
      param :form, :artist_riders, :string, :optional, "Artist array of riders objects
                                [{'rider_type': 'stage|backstage|hospitality|technical', 'uploaded_file_base64': '', 'description': '', 'is_flexible': ''}, {...}]"
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
        @account = Account.new(account_params)
        @account.user = @user
        @account.is_verified = true

        if @account.save
            set_image
            set_base64_image

            return if not set_fan_params
            return if not set_venue_params
            return if not set_artist_params

            #AccessHelper.grant_account_access(@account)
            render json: @account, extended: true, my: true, except: :password, status: :created
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # PUT /accounts/<account_id>
    swagger_api :update do
      summary "Updates existing account"
      param :path, :id, :integer, :required, "Account id"
      param :form, :user_name, :string, :optional, "Account's name"
      param :form, :display_name, :string, :optional, "Account's name to display"
      param :form, :phone, :string, :optional, "Account's phone"
      param :form, :image_base64, :string, :optional, "Image base64 string"
      param :form, :image_description, :string, :optional, "Image description"
      param_list :form, :image_type, :string, :optional, "Image type", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                        "stadium_arena", "outdoor_space", "other"]
      param :form, :image_type_description, :string, :optional, "Image other type description"
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :venue_video_links, :string, :optional, "Array of links"
      param :form, :artist_videos, :string, :optional, "Array of link objects [{'name': '', 'album_name': '', 'link': ''}, {...}]"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :genres, :string, :optional, "Fan/Artist/Venue (public only) Genres ['genre1', 'genre2', ...]"
      param :form, :address, :string, :optional, "Fan/Venue address"
      param :form, :preferred_address, :string, :optional, "Artist preferred address to perform"
      param :form, :lat, :float, :optional, "Fan/Artist/Venue lat"
      param :form, :lng, :float, :optional, "Fan/Artist/Venue lng"
      param :form, :first_name, :string, :optional, "Fan/Artist first name"
      param :form, :last_name, :string, :optional, "Fan/Artist last name"
      param :form, :description, :string, :optional, "Venue description"
      param :form, :fax, :string, :optional, "Venue fax (public_venue only)"
      param :form, :bank_name, :string, :optional, "Venue bank name (public_venue only)"
      param :form, :account_bank_number, :string, :optional, "Venue account bank number (public_venue only)"
      param :form, :account_bank_routing_number, :string, :optional, "Venue account routing number (public_venue only)"
      param :form, :capacity, :integer, :optional, "Venue capacity"
      param :form, :num_of_bathrooms, :integer, :optional, "Venue num of bathrooms (public_venue only)"
      param :form, :min_age, :integer, :optional, "Venue min age (public_venue only)"
      param_list :form, :venue_type, :string, :optional, "Venue type", ["public_venue", "private_residence"]
      param_list :form, :type_of_space, :string, :optional, "Venue type of space (public_venue only)", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                                                        "stadium_arena", "outdoor_space", "other"]
      param :form, :other_genre_description, :string, :optional, "Venue other genre description (for public venue if genre other)"
      param :form, :has_bar, :boolean, :optional, "Has venue bar? (public_venue only)"
      param_list :form, :located, :string, :optional, "Venue located (public_venue only)", ["indoors", "outdoors", "both"]
      param :form, :dress_code, :string, :optional, "Venue dress code (public_venue only)"
      param :form, :has_vr, :boolean, :optional, "Has venue vr?"
      param :form, :audio_description, :string, :optional, "Venue audio description (public_venue only)"
      param :form, :lighting_description, :string, :optional, "Venue lighting description (public_venue only)"
      param :form, :stage_description, :string, :optional, "Venue stage description (public_venue only)"
      param :form, :dates, :string, :optional, "Venue dates [{'begin_date': '', 'end_date': '', 'is_available': '',
                                                            'price': '', 'booking_notice': 'same_day|one_day|two_seven_days'}, {...}]"
      param :form, :emails, :string, :optional, "Venue dates [{'name': '', 'email': ''}, {...}]"
      param :form, :office_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :operating_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :price, :integer, :optional, "Venue (public only) price"
      param :form, :country, :string, :optional, "Venue (public only) country"
      param :form, :city, :string, :optional, "Venue (public only) city"
      param :form, :state, :string, :optional, "Venue (public only) state"
      param :form, :zipcode, :integer, :optional, "Venue (public only) zipcode"
      param :form, :minimum_notice, :integer, :optional, "Venue (public only) minimum notice time"
      param :form, :is_flexible, :boolean, :optional, "Is venue (public only) time flexible"
      param :form, :price_for_daytime, :integer, :optional, "Venue (public only) price for daytime"
      param :form, :price_for_nighttime, :integer, :optional, "Venue (public only) price for nighttime"
      param :form, :performance_time_from, :time, :optional, "Venue (public only) performance time from"
      param :form, :performance_time_to, :time, :optional, "Venue (public only) performance time to"
      param :form, :vr_capacity, :integer, :optional, "Venue vr tickets available"
      param :form, :about, :string, :optional, "About artist"
      param :form, :stage_name, :string, :optional, "Artist stage name"
      param :form, :manager_name, :string, :optional, "Artist's manager name"
      param :form, :artist_email, :string, :optional, "Artist's email"
      param :form, :audio_links, :string, :optional, "Array of links to audio of artist [{'song_name': '', 'album_name': '', 'audio_link': ''}, {...}]"
      param :form, :artist_albums, :string, :optional, "Array of artist albums objects [{'album_name': '', 'album_artwork': '', 'album_link': ''}, {...}]"
      param :form, :available_dates, :string, :optional, "Artist available dates [{'begin_date': '', 'end_date': ''}, {...}]"
      param :form, :performance_min_time, :integer, :optional, "Artist min time to perform (hr)"
      param :form, :performance_max_time, :integer, :optional, "Artist max time to perform (hr)"
      param :form, :price_from, :integer, :optional, "Artist min price to perform"
      param :form, :price_to, :integer, :optional, "Artist max time to perform"
      param :form, :additional_hours_price, :integer, :optional, "Artist price for additional hours"
      param :form, :is_hide_pricing_from_profile, :boolean, :optional, "Hide artist pricing from profile?"
      param :form, :is_hide_pricing_from_search, :boolean, :optional, "Hide artist pricing from search?"
      param :form, :days_to_travel, :integer, :optional, "Artist days to travel"
      param :form, :is_perform_with_band, :boolean, :optional, "Is artist perform with band?"
      param :form, :can_perform_without_band, :boolean, :optional, "Can artist perform without band?"
      param :form, :is_perform_with_backing_vocals,:boolean, :optional, "Is artist perform with backing vocals?"
      param :form, :can_perform_without_backing_vocals, :boolean, :optional, "Can artist perform without backing vocals?"
      param :form, :is_permitted_to_stream, :boolean, :optional, "Is artist give permission to stream?"
      param :form, :is_permitted_to_advertisement,:boolean, :optional, "Is artist give permission to advertisement?"
      param :form, :has_conflict_contracts, :boolean, :optional, "Has artist conflict contracts to advertisement?"
      param :form, :conflict_companies_names, :string, :optional, "Names of artist's conflict companies"
      param :form, :preferred_venue_text,:string, :optional, "Artist other preferred venue types"
      param :form, :min_time_to_book, :integer, :optional, "Artist min time to book"
      param :form, :min_time_to_free_cancel, :integer, :optional, "Artist min time to cancel"
      param :form, :late_cancellation_fee, :integer, :optional, "Artist late cancellation fee"
      param :form, :refund_policy, :string, :optional, "Artist refund policy"
      param :form, :artist_riders, :string, :optional, "Artist array of riders objects
                                [{'rider_type': 'stage|backstage|hospitality|technical', 'uploaded_file_base64': '', 'description': '', 'is_flexible': ''}, {...}]"
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
        set_image
        set_base64_image

        return if not set_fan_params
        return if not set_venue_params
        return if not set_artist_params
        if @account.update(account_update_params)
            render json: @account, extended: true, my: true, except: :password, status: :ok
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    swagger_api :search do
      summary "Search account"
      param :query, :text, :string, :optional, "Search query"
      param_list :query, :type, :string, :optional, "Account type to display", ["venue", "artist", "fan"]
      param :query, :price_from, :integer, :optional, "Artist/Venue price from"
      param :query, :price_to, :integer, :optional, "Artist/Venue price to"
      param :query, :address, :string, :optional, "Artist/Venue address"
      param :query, :capacity_from, :integer, :optional, "Venue capacity from"
      param :query, :capacity_to, :integer, :optional, "Venue capacity to"
      param :query, :types_of_space, :string, :optional, "Venue types of space array ['night_club', 'concert_hall', ...]"
      param :query, :genres, :string, :optional, "Array of genres ['rap', 'rock', ....]"
      param :query, :extended, :boolean, :optional, "Extended info"
      param :query, :sort_by_popularity, :boolean, :optional, "Sort results by popularity"
      param :query, :limit, :integer, :optional, "Limit"
      param :query, :offset, :integer, :optional, "Offset"
    end
    def search
      @extended = true
      set_extended

      @accounts = Account.all
      search_text
      search_type
      search_price
      search_genres
      search_address
      search_capacity
      search_type_of_space
      sort_results

      render json: @accounts.limit(params[:limit]).offset(params[:offset]), extended: @extended, status: :ok
    end

    # POST accounts/1/verify
    swagger_api :verify do
      summary "Verify account"
      param :path, :id, :integer, :required, "Account id"
      response :unprocessable_entity
      response :not_found
    end
    def verify
      @to_find.is_verified = true
      update_events
      @to_find.save!

      render status: :ok
    end

    swagger_api :delete do
      summary "Delete account"
      param :path, :id, :integer, :required, "Account id"
      param :form, :password, :string, :required, "Account password"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :unauthorized
      response :forbidden
    end
    def delete
      if User.encrypt_password(params[:password]) == @account.user.password
        @account.destroy
        render status: :ok
      else
        render status: :forbidden
      end
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def find_account
        @to_find = Account.find(params[:id])
    end

    def find_follower_account
      @to_find = Account.find(params[:follower_id])
    end

    def find_image
        @image = Image.find(params[:image_id])
    end

    def authorized?
      if request.headers['Authorization']
        user = AuthorizeHelper.authorize(request)
        return (user != nil and user == @to_find.user)
      end
    end

    def authorize_user
        @user = AuthorizeHelper.authorize(request)
        render status: :unauthorized if @user == nil
    end

    def authorize_account
        @user = AuthorizeHelper.authorize(request)
        @account = Account.find(params[:id])
        render status: :unauthorized if @user == nil or @account.user != @user
    end

    def set_image
        if params[:image]
            #@account.image.delete if @account.image != nil
            image = Image.new(description: params[:image_description], base64: Base64.encode64(File.read(params[:image].path)))
            image.save
            @account.image = image
            @account.images << image

            set_image_type(image)
        end
    end

    def set_base64_image
        if params[:image_base64]
            #@account.image.delete if @account.image != nil  
            image = Image.new(description: params[:image_description], base64: params[:image_base64])
            image.save
            @account.image = image
            @account.images << image

            set_image_type(image)
        end
    end

    def set_image_type(image)
        if params[:image_type]
            obj = ImageType.new(image_type: params[:image_type])
            if params[:image_type_description]
              obj.description = params[:image_type_description]
            end
            obj.save

            image.image_type = obj
        end
    end

    def set_fan_params
        if @account.account_type == 'fan'
            if @account.fan 
                @fan = @account.fan
                @fan.update(fan_params)
            else
                @fan = Fan.new(fan_params)
                render json: @fan.errors and return false if not @fan.save
                @account.fan_id = @fan.id
                @account.save
            end
            set_fan_genres
        end
        return true
    end

    def set_fan_genres
        if params[:genres]
            @fan.genres.clear
            params[:genres].each do |genre|
                obj = FanGenre.new(genre: genre)
                obj.save
                @fan.genres << obj
            end
            @fan.save
        end
    end

    def set_venue_params
        if @account.account_type == 'venue'            
            if @account.venue 
                @venue = @account.venue
                @venue.update(venue_params)
                params.each do |param|
                    if HistoryHelper::VENUE_FIELDS.include?(param.to_sym)
                        action = AccountUpdate.new(action: :update, updated_by: @account.id, account_id: @account.id, field: param)
                        action.save
                    end
                end
            else
                @venue = Venue.new(venue_params)
                render json: @venue.errors and return false if not @venue.save
                @account.venue_id = @venue.id
                render json: @account.errors and return false if not @account.save!
            end
            
            return false if not set_public_venue
            set_venue_genres
            set_venue_dates
            set_venue_emails
            set_venue_video_links
            set_venue_office_hours
            set_venue_operating_hours
        end
        return true
    end

    def set_public_venue
      if @venue.venue_type != 'private_residence'
        if @venue.public_venue
          @public_venue = @venue.public_venue
          @public_venue.update(public_venue_params)
        else
          @public_venue = PublicVenue.new(public_venue_params)
          @public_venue.venue_id = @venue.id
          render json: @public_venue.errors and return false if not @public_venue.save
        end
        @venue.public_venue = @public_venue
      end
      return true
    end

    def set_venue_genres
      if params[:genres] and @venue.venue_type == 'public_venue'
        @venue.public_venue.genres.clear
        params[:genres].each do |genre|
          obj = VenueGenre.new(genre: genre)
          obj.save
          @venue.public_venue.genres << obj
        end
        @venue.public_venue.save
      end
    end

    def set_venue_dates
        if params[:dates]
            @venue.dates.clear
            params[:dates].each do |date|
                obj = VenueDate.new(venue_dates_params(date))
                obj.save
                @venue.dates << obj
            end
            @venue.save
        end
    end

    def set_venue_emails
        if params[:emails]
            @venue.emails.clear
            params[:emails].each do |email|
                obj = VenueEmail.new(venue_email_params(email))
                obj.save
                @venue.emails << obj
            end
            @venue.save
        end
    end

    def set_venue_office_hours
        if params[:office_hours]
            @venue.office_hours.clear
            params[:office_hours].each do |hour|
                obj = VenueOfficeHour.new(venue_office_hours_params(hour))
                obj.save
                @venue.office_hours << obj
            end
            @venue.save
        end
    end

    def set_venue_operating_hours
        if params[:operating_hours]
            @venue.operating_hours.clear
            params[:operating_hours].each do |hour|
                obj = VenueOperatingHour.new(venue_operating_hours_params(hour))
                obj.save
                @venue.operating_hours << obj
            end
            @venue.save
        end
    end

    def set_venue_video_links
      if params[:venue_video_links]
        @venue.venue_video_links.clear
        params[:venue_video_links].each do |link|
          obj = VenueVideoLink.new(video_link: link)
          obj.save
          @venue.venue_video_links << obj
        end
        @venue.save
      end
    end

    def set_artist_params
        if @account.account_type == 'artist'
            if @account.artist
                @artist = @account.artist
                @artist.update(artist_params)
                params.each do |param|
                    if HistoryHelper::ARTIST_FIELDS.include?(param.to_sym)
                        action = AccountUpdate.new(action: :update, updated_by: @account.id, account_id: @account.id, field: param)
                        action.save
                    end
                end
            else
                @artist = Artist.new(artist_params)
                render json: @artist.errors and return false if not @artist.save 
                @account.artist_id = @artist.id
                render json: @account.errors and return false if not @account.save
            end
            set_artist_genres
            set_artist_audios
            set_artist_albums
            set_artist_video_links
            set_artist_dates
            set_artist_preferred_venues
            set_artist_riders
        end
        return true
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

    def set_artist_video_links
      if params[:artist_videos]
        @artist.artist_videos.clear
        params[:artist_videos].each do |link|
          obj = ArtistVideo.new(artist_video_params(link))
          obj.save
          @artist.artist_videos << obj
        end
        @artist.save
      end
    end

    def set_artist_albums
      if params[:artist_albums]
        @artist.artist_albums.clear
        params[:artist_albums].each do |album|
          obj = ArtistAlbum.new(artist_album_params(album))
          obj.save
          @artist.artist_albums << obj
        end
        @artist.save
      end
    end

    def set_artist_riders
      if params[:artist_riders]
        @artist.artist_riders.clear
        params[:artist_riders].each do |rider|
          obj = ArtistRider.new(artist_rider_params(rider))
          obj.save
          @artist.artist_riders<< obj
        end
        @artist.save
      end
    end

    def set_artist_audios
      if params[:audio_links]
        @artist.audio_links.clear
        @artist.save
        params[:audio_links].each do |link|
          obj = AudioLink.new(artist_audio_params(link))
          obj.save
          @artist.audio_links << obj
        end
        @artist.save
      end
    end

    def set_artist_dates
      if params[:available_dates]
        @artist.available_dates.clear
        params[:available_dates].each do |date_range|
          obj = ArtistDate.new(artist_dates_params(date_range))
          obj.save
          @artist.available_dates << obj
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

    def set_extended
        if params[:extended] == 'true'
            @extended = true
        elsif params[:extended] == 'false'
            @extended = false
        end
    end

    def search_text
      if params[:text]
        @accounts = @accounts.search(params[:text])
      end
    end

    def search_type
      if params[:type]
        @accounts = @accounts.where(account_type: params[:type])
      end
    end

    def search_price
      if params[:type] == 'artist'
        if params[:price_from]
          @accounts = @accounts.joins(:artist).where("artists.price_from >= :price", {:price => params[:price_from]})
        end
        if params[:price_to]
          @accounts = @accounts.joins(:artist).where("artists.price_to <= :price", {:price => params[:price_to]})
        end
      elsif params[:type] == 'venue'
        if params[:price_from]
          @accounts = @accounts.joins(:venue => :public_venue).where("public_venues.price >= :price", {:price => params[:price_from]})
        end
        if params[:price_to]
          @accounts = @accounts.joins(:venue => :public_venue).where("public_venues.price <= :price", {:price => params[:price_to]})
        end
      end
    end

    def collect_genres(_class)
      genres = []
      params[:genres].each do |genre|
        genres.append(_class.genres[genre])
      end

      return genres
    end

    def search_genres
      if params[:genres]
        if params[:type] == 'artist'
          genres = collect_genres(ArtistGenre)
          @accounts = @accounts.joins(:artist => :genres).where(:artist_genres => {genre: genres})
        elsif params[:type] == 'venue'
          genres = collect_genres(VenueGenre)
          @accounts = @accounts.joins(:venue => {:public_venue => :genres}).where(:venue_genres => {genre: genres})
        elsif params[:type] == 'fan'
          genres = collect_genres(FanGenre)
          @accounts = @accounts.joins(:fan => :genres).where(:fan_genres => {genre: genres})
        end
      end
    end

    def search_address
      if params[:address]
        if params[:type] == 'artist'
          artists = Artist.near(params[:address]).select{|a| a.id}
          @accounts = @accounts.where(artist_id: artists)
        elsif params[:type] == 'venue'
          venues = Venue.near(params[:address]).select{|a| a.id}
          @accounts = @accounts.where(venue_id: venues)
        end
      end
    end

    def search_capacity
      if params[:capacity_from] and params[:capacity_to] and params[:type] == "venue"
        @accounts = @accounts.joins(:venue).where(venues: {capacity: params[:capacity_from]..params[:capacity_to]})
      end
    end

    def search_type_of_space
      if params[:types_of_space] and params[:type] == "venue"
        types_of_space = []
        params[:types_of_space].each do |type_of_space|
          types_of_space.append(PublicVenue.type_of_spaces[type_of_space])
        end

        @accounts = @accounts.joins(
          :venue => :public_venue
        ).where(public_venues: {type_of_space: types_of_space})
      end
    end

    def update_events
      Event.where(creator_id: @to_find.id).each do |event|
        event.artist_events.where(status: 'pending').each do |relation|
          relation.status = 'ready'
          relation.save
        end

        event.venue_events.where(status: 'pending').each do |relation|
          relation.status = 'ready'
          relation.save
        end
      end
    end

    def sort_results
      if params[:sort_by_popularity]
        @accounts = @accounts.select(
          "accounts.*, COUNT(followers.id) as followers_count"
        ).left_joins(:followers).group('id').order('followers_count')
      end
    end

    def account_params
        params.permit(:user_name, :display_name, :phone, :account_type)
    end

    def account_update_params 
        params.permit(:user_name, :display_name, :phone)
    end

    def fan_params
        params.permit(:bio, :address, :lat, :lng, :first_name, :last_name)
    end

    def venue_params
        params.permit(:description, :capacity, :venue_type, :has_vr, :address, :lat, :lng, :vr_capacity)
    end

    def public_venue_params
      params.permit(:fax, :bank_name, :account_bank_number, :account_bank_routing_number,
                    :num_of_bathrooms, :min_age, :has_bar, :located, :dress_code, :audio_description,
                    :lighting_description, :stage_description, :type_of_space, :price, :country, :city,
                    :state, :zipcode, :minimum_notice, :is_flexible, :price_for_daytime, :price_for_nighttime,
                    :performance_time_from, :performance_time_to, :other_genre_description)
    end
    
    def venue_dates_params(date)
        date.permit(:begin_date, :end_date, :is_available, :price, :booking_notice)
    end

    def venue_email_params(email)
        email.permit(:name, :email)
    end

    def venue_office_hours_params(hour)
        hour.permit(:begin_time, :end_time, :day)
    end

    def venue_operating_hours_params(hour)
        hour.permit(:begin_time, :end_time, :day)
    end

    def artist_params
        params.permit(:about, :lat, :lng, :preferred_address, :first_name, :last_name, :stage_name, :manager_name,
                      :facebook, :twitter, :instagram, :snapchat, :spotify, :soundcloud, :youtube,
                      :performance_min_time, :performance_max_time, :price_from, :price_to, :additional_hours_price,
                      :is_hide_pricing_from_profile, :is_hide_pricing_from_search, :days_to_travel,
                      :is_perform_with_band, :can_perform_without_band, :is_perform_with_backing_vocals,
                      :can_perform_without_backing_vocals, :is_permitted_to_stream, :is_permitted_to_advertisement,
                      :has_conflict_contracts, :conflict_companies_names, :preferred_venue_text,
                      :min_time_to_book, :min_time_to_free_cancel, :late_cancellation_fee, :refund_policy, :artist_email)
    end

    def artist_audio_params(link)
      link.permit(:audio_link, :song_name, :album_name)
    end

    def artist_album_params(album)
      album.permit(:album_name, :album_artwork, :album_link)
    end

    def artist_rider_params(rider)
      rider.permit(:rider_type, :description, :is_flexible, :uploaded_file_base64)
    end

    def artist_dates_params(date)
      date.permit(:begin_date, :end_date)
    end

    def artist_video_params(video)
      video.permit(:link, :name, :album_name)
    end

end
