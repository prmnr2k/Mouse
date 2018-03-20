class AccountsController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:get_events, :update,  :upload_image, :follow, :unfollow, :follow_multiple, :delete]  
    before_action :find_account, only: [:get, :get_images, :get_followers, :get_followed, :get_updates]
    before_action :find_follower_account, only: [:follow, :unfollow]
    swagger_controller :accounts, "Accounts"


    # GET /accounts/<id>
    swagger_api :get do
      summary "Retrieve account by id"
      param :path, :id, :integer, :required, "Account id"
      param :query, :extended, :boolean, :optional, "Need extended info"
      response :not_found
    end
    def get
        @extended = true
        set_extended
        render json: @to_find, extended: @extended, status: :ok
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
       @events = @account.events
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
            images: @to_find.images.limit(params[:limit]).offset(params[:offset]).pluck(:id)
        }
    end

    #POST /accounts/images/<account_id>
    swagger_api :upload_image do
      summary "Upload image to Account"
      param :path, :id, :integer, :required, "Account id"
      param :form, :image, :file, :required, "Image to upload"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :unauthorized
      response :not_found
    end
    def upload_image
        image = Image.new(base64: Base64.encode64(File.read(params[:image].path)))
        image.account = @account
        if image.save
            @account.images << image
            @account.image = image
            render json: @account, status: :ok
            
        else
            render json: image.errors, status: :unprocessable_entity
        end
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
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :video_links, :string, :optional, "Array of links"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :genres, :string, :optional, "Fan/Artist/Venue (public only) Genres ['genre1', 'genre2', ...]"
      param :form, :address, :string, :optional, "Fan/Artist/Venue address"
      param :form, :lat, :float, :optional, "Fan/Artist/Venue lat"
      param :form, :lng, :float, :optional, "Fan/Artist/Venue lng"
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
      param :form, :has_bar, :boolean, :optional, "Has venue bar? (public_venue only)"
      param_list :form, :located, :string, :optional, "Venue located (public_venue only)", ["indoors", "outdoors", "other_location"]
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
      param :form, :about, :string, :optional, "About artist"
      param :form, :price, :integer, :optional, "Artist/Venue (public only) price"
      param :form, :is_price_private, :boolean, :optional, "Is artist price private"
      param :form, :technical_rider, :string, :optional, "Artist technical rider"
      param :form, :stage_rider, :string, :optional, "Artist stage rider"
      param :form, :backstage_rider, :string, :optional, "Artist backstage rider"
      param :form, :first_name, :string, :optional, "Artist first name"
      param :form, :last_name, :string, :optional, "Artist last name"
      param :form, :hospitality, :string, :optional, "Artist hospitality"
      param :form, :audio_links, :string, :optional, "Array of links to audio of artist"
      param :form, :available_dates, :string, :optional, "Artist available dates [{'begin_date': '', 'end_date': '', {...}]"
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

        if @account.save
            set_image
            set_base64_image

            set_fan_params
            set_venue_params
            set_artist_params
            set_video_links

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
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :video_links, :string, :optional, "Array of links"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :genres, :string, :optional, "Fan/Artist/Venue (public only) Genres ['genre1', 'genre2', ...]"
      param :form, :address, :string, :optional, "Fan/Artist/Venue address"
      param :form, :lat, :float, :optional, "Fan/Artist/Venue lat"
      param :form, :lng, :float, :optional, "Fan/Artist/Venue lng"
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
      param :form, :has_bar, :boolean, :optional, "Has venue bar? (public_venue only)"
      param_list :form, :located, :string, :optional, "Venue located (public_venue only)", ["indoors", "outdoors", "other_location"]
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
      param :form, :about, :string, :optional, "About artist"
      param :form, :price, :integer, :optional, "Artist/Venue (public only) price"
      param :form, :is_price_private, :boolean, :optional, "Is artist price private"
      param :form, :technical_rider, :string, :optional, "Artist technical rider"
      param :form, :stage_rider, :string, :optional, "Artist stage rider"
      param :form, :backstage_rider, :string, :optional, "Artist backstage rider"
      param :form, :first_name, :string, :optional, "Artist first name"
      param :form, :last_name, :string, :optional, "Artist last name"
      param :form, :hospitality, :string, :optional, "Artist hospitality"
      param :form, :audio_links, :string, :optional, "Array of links to audio of artist"
      param :form, :available_dates, :string, :optional, "Artist available dates [{'begin_date': '', 'end_date': '', {...}]"
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

        set_fan_params
        set_venue_params
        set_artist_params
        set_video_links
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
            image = Image.new(base64: Base64.encode64(File.read(params[:image].path)))
            #image.save
            @account.image = image
            @account.images << image
        end
    end

    def set_base64_image
        if params[:image_base64]
            #@account.image.delete if @account.image != nil
            image = Image.new(base64: params[:image_base64])
            #image.save
            @account.image = image
            @account.images << image
        end
    end

    def set_fan_params
        if @account.account_type == 'fan'
            if @account.fan 
                @fan = @account.fan
                @fan.update(fan_params)
            else
                @fan = Fan.new(fan_params)
                render @fan.errors and return if not @fan.save
                @account.fan_id = @fan.id
                @account.save
            end
            set_fan_genres
        end
    end

    def set_fan_genres
        if params[:genres]
            @fan.genres.clear
            params[:genres].each do |genre|
                obj = FanGenre.new(genre: genre)
                obj.save
                @fan.genres << obj
            end
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
                render @venue.errors and return if not @venue.save
                @account.venue_id = @venue.id
                @account.save!
            end
            
            set_public_venue
            set_venue_genres
            set_venue_dates
            set_venue_emails
            set_venue_office_hours
            set_venue_operating_hours
        end
    end

    def set_public_venue
      if @venue.venue_type != 'private_residence'
        if @venue.public_venue
          @public_venue = @venue.public_venue
          @public_venue.update(public_venue_params)
        else
          @public_venue = PublicVenue.new(public_venue_params)
          @public_venue.venue_id = @venue.id
          render @public_venue.errors and return if not @public_venue.save
        end
        @venue.public_venue = @public_venue
      end
    end

    def set_venue_genres
      if params[:genres] and @venue.venue_type == 'public_venue'
        @venue.public_venue.genres.clear
        params[:genres].each do |genre|
          obj = VenueGenre.new(genre: genre)
          obj.save
          @venue.public_venue.genres << obj
        end
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
                render @artist.errors and return if not @artist.save
                @account.artist_id = @artist.id
                @account.save
            end
            set_artist_genres
            set_artist_audios
            set_artist_dates
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
        end
    end

    def set_video_links
      if params[:video_links]
        @account.account_video_links.clear
        params[:video_links].each do |link|
          obj = AccountVideoLink.new(link: link)
          obj.save
          @account.account_video_links << obj
        end
      end
    end

    def set_artist_audios
      if params[:audio_links]
        @artist.audio_links.clear
        params[:audio_links].each do |link|
          obj = AudioLink.new(audio_link: link)
          obj.save
          @artist.audio_links << obj
        end
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
      if params[:price_from] and params[:price_to] and params[:type] == 'artist'
        @accounts = @accounts.joins(:artist).where(price: params[:price_from]..params[:price_to])
      elsif params[:price_from] and params[:price_to] and params[:type] == 'venue'
        @accounts = @accounts.joins(:venue => :public_venue).where(price: params[:price_from]..params[:price_to])
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
          @accounts = @accounts.joins(:venue => :genres).where(:venue_genres => {genre: genres})
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
        params.permit(:bio, :address, :lat, :lng)
    end

    def venue_params
        params.permit(:description, :capacity, :venue_type, :has_vr, :address, :lat, :lng)
    end

    def public_venue_params
      params.permit(:fax, :bank_name, :account_bank_number, :account_bank_routing_number,
                    :num_of_bathrooms, :min_age, :has_bar, :located, :dress_code, :audio_description,
                    :lighting_description, :stage_description, :type_of_space, :price)
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
        params.permit(:about, :lat, :lng, :address, :price, :is_price_private, :technical_rider,
                      :stage_rider, :backstage_rider, :first_name, :last_name, :hospitality,
                      :facebook, :twitter, :instagram, :snapchat, :spotify, :soundcloud, :youtube)
    end

    def artist_dates_params(date)
      date.permit(:begin_date, :end_date)
    end

end
