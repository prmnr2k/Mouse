class AccountsController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:update, :upload_image, :follow, :unfollow]  
    before_action :find_account, only: [:get, :follow, :unfollow, :get_images, :get_followers, :get_followed]  
    before_action :find_image, only: [:delete_image]
    swagger_controller :accounts, "Accounts"


    # GET /accounts/<id>
    swagger_api :get do
      summary "Retrieve account by id"
      param :path, :id, :integer, :required, "Account id"
      param :query, :extended, :boolean, :required, "Need extended info"
      response :not_found
    end
    def get
        @extended = true
        set_extended
        render json: @to_find, extended: @extended, status: :ok
    end

    # GET /accounts/
    swagger_api :get_all do
      summary "Retrieve list of accounts"
      param :query, :extended, :boolean, :required, "Need extended info"
      param :query, :limit, :integer, :required, "Limit"
      param :query, :offset, :integer, :required, "Offset"
      response :ok
    end
    def get_all
        @accounts = Account.all
        @extended = false
        set_extended
        render json: @accounts.limit(params[:limit]).offset(params[:offset]), extended: @extended, status: :ok
    end

    # GET /accounts/my
    swagger_api :get_my_accounts do
      summary "Retrieve list of my accounts"
      param :query, :extended, :boolean, :required, "Need extended info"
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
      param :query, :limit, :integer, :required, "Limit"
      param :query, :offset, :integer, :required, "Offset"
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
      param :path, :account_id, :integer, :required, "Account id"
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
            render json: @account, status: :ok
            
        else
            render json: image.errors, status: :unprocessable_entity
        end
    end


    #POST /accounts/follow/<account_id>
    swagger_api :follow do
      summary "Subscribe for account"
      param :path, :account_id, :integer, :required, "My account id"
      param :query, :id, :integer, :required, "Following account id"
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

    # GET /accounts/followers/<id>
    swagger_api :get_followers do
      summary "Retrieve list of followers"
      param :path, :id, :integer, :required, "Account id"
      param :query, :offset, :integer, :required, "Offset"
      param :query, :limit, :integer, :required, "Limit"
      response :not_found
    end
    def get_followers 
        render json: {
            total_count: @to_find.followers.count,
            followers: @to_find.followers.limit(params[:limit]).offset(params[:offset])
        }
    end

    # GET /accounts/following/<id>
    swagger_api :get_followed do
      summary "Retrieve list of followers"
      param :path, :id, :integer, :required, "Account id"
      param :query, :offset, :integer, :required, "Offset"
      param :query, :limit, :integer, :required, "Limit"
      response :not_found
    end
    def get_followed
        render json: {
            total_count: @to_find.following.count,
            following: @to_find.following.limit(params[:limit]).offset(params[:offset])
        }
    end

    #DELETE /accounts/unfollow/<account_id>
    swagger_api :unfollow do
      summary "Unubscribe from account"
      param :path, :account_id, :integer, :required, "My account id"
      param :query, :id, :integer, :required, "Following account id"
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
      param :form, :display_name, :string, :required, "Account's name to display"
      param :form, :phone, :string, :required, "Account's phone"
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :address, :string, :optional, "Fan address"
      param :form, :lat, :float, :optional, "Fan lat"
      param :form, :lng, :float, :optional, "Fan lng"
      param :form, :description, :string, :optional, "Venue description"
      param :form, :phone, :string, :optional, "Venue phone"
      param :form, :fax, :string, :optional, "Venue fax"
      param :form, :bank_name, :string, :optional, "Venue bank name"
      param :form, :account_bank_number, :string, :optional, "Venue account bank number"
      param :form, :account_bank_routing_number, :string, :optional, "Venue account routing number"
      param :form, :capacity, :integer, :optional, "Venue capacity"
      param :form, :num_of_bathrooms, :integer, :optional, "Venue num of bathrooms"
      param :form, :min_age, :integer, :optional, "Venue min age"
      param_list :form, :venue_type, :integer, :optional, "Venue type", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                         "stadium_arena", "outdoor_space", "private_residence", "other"]
      param :form, :has_bar, :boolean, :optional, "Has venue bar?"
      param_list :form, :located, :string, :optional, "Venue located", ["indoors", "outdoors", "other_location"]
      param :form, :dress_code, :string, :optional, "Venue dress code"
      param :form, :has_vr, :boolean, :optional, "Has venue vr?"
      param :form, :audio_description, :string, :optional, "Venue audio description"
      param :form, :lighting_description, :string, :optional, "Venue lighting description"
      param :form, :stage_description, :string, :optional, "Venue stage description"
      param :form, :address, :string, :optional, "Venue address"
      param :form, :lat, :float, :optional, "Venue lat"
      param :form, :lng, :float, :optional, "Venue lng"
      param :form, :dates, :string, :optional, "Venue dates [{'begin_date': '', 'end_date': '', 'is_available': '',
                                                            'price': '', 'booking_notice': 'same_day|one_day|two_seven_days'}, {...}]"
      param :form, :emails, :string, :optional, "Venue dates [{'name': '', 'email': ''}, {...}]"
      param :form, :office_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :operating_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :about, :string, :optional, "About artist"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :unauthorized
    end
    def create
        @account = Account.new(account_params)
        @account.user = @user

        if @account.save
            set_image

            set_fan_params
            set_venue_params
            set_artist_params

            #AccessHelper.grant_account_access(@account)
            render json: @account, extended: true, except: :password, status: :created
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # PUT /accounts/<account_id>
    swagger_api :update do
      summary "Updates existing account"
      param :path, :account_id, :integer, :required, "Account id"
      param :form, :user_name, :string, :required, "Account's name"
      param :form, :display_name, :string, :required, "Account's name to display"
      param :form, :phone, :string, :required, "Account's phone"
      param_list :form, :account_type, :string, :required, "Account type", ["venue", "artist", "fan"]
      param :form, :image, :file, :optional, "Image"
      param :form, :bio, :string, :optional, "Fan bio"
      param :form, :address, :string, :optional, "Fan address"
      param :form, :lat, :float, :optional, "Fan lat"
      param :form, :lng, :float, :optional, "Fan lng"
      param :form, :description, :string, :optional, "Venue description"
      param :form, :phone, :string, :optional, "Venue phone"
      param :form, :fax, :string, :optional, "Venue fax"
      param :form, :bank_name, :string, :optional, "Venue bank name"
      param :form, :account_bank_number, :string, :optional, "Venue account bank number"
      param :form, :account_bank_routing_number, :string, :optional, "Venue account routing number"
      param :form, :capacity, :integer, :optional, "Venue capacity"
      param :form, :num_of_bathrooms, :integer, :optional, "Venue num of bathrooms"
      param :form, :min_age, :integer, :optional, "Venue min age"
      param_list :form, :venue_type, :integer, :optional, "Venue type", ["night_club", "concert_hall", "event_space", "theatre", "additional_room",
                                                                          "stadium_arena", "outdoor_space", "private_residence", "other"]
      param :form, :has_bar, :boolean, :optional, "Has venue bar?"
      param_list :form, :located, :string, :optional, "Venue located", ["indoors", "outdoors", "other_location"]
      param :form, :dress_code, :string, :optional, "Venue dress code"
      param :form, :has_vr, :boolean, :optional, "Has venue vr?"
      param :form, :audio_description, :string, :optional, "Venue audio description"
      param :form, :lighting_description, :string, :optional, "Venue lighting description"
      param :form, :stage_description, :string, :optional, "Venue stage description"
      param :form, :address, :string, :optional, "Venue address"
      param :form, :lat, :float, :optional, "Venue lat"
      param :form, :lng, :float, :optional, "Venue lng"
      param :form, :dates, :string, :optional, "Venue dates [{'begin_date': '', 'end_date': '', 'is_available': '',
                                                            'price': '', 'booking_notice': 'same_day|one_day|two_seven_days'}, {...}]"
      param :form, :emails, :string, :optional, "Venue dates [{'name': '', 'email': ''}, {...}]"
      param :form, :office_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :operating_hours, :string, :optional, "Venue dates [{'begin_time': '', 'end_time': '', 'day': ''}, {...}]"
      param :form, :about, :string, :optional, "About artist"
      param :header, 'Authorization', :string, :required, 'Authentication token'
      response :unprocessable_entity
      response :unauthorized
    end
    def update
        set_image
        
        set_fan_params
        set_venue_params
        set_artist_params
        if @account.update(account_params)
            render json: @account, extended: true, except: :password, status: :ok
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def find_account
        @to_find = Account.find(params[:id])
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
        @account = Account.find(params[:account_id])
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
            else
                @venue = Venue.new(venue_params)
                render @venue.errors and return if not @venue.save
                @account.venue_id = @venue.id
                @account.save!
            end
        end
        set_venue_dates
        set_venue_emails
        set_venue_office_hours
        set_venue_operating_hours
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
            else
                @artist = Artist.new(artist_params)
                render @artist.errors and return if not @artist.save
                @account.artist_id = @artist.id
                @account.save
            end
            set_artist_genres
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

    def set_extended
        if params[:extended] == 'true'
            @extended = true
        elsif params[:extended] == 'false'
            @extended = false
        end
    end

    def account_params
        params.permit(:user_name, :display_name, :phone, :account_type)
    end

    def fan_params
        params.permit(:bio, :address, :lat, :lng)
    end

    def venue_params
        params.permit(:description, :phone, :fax, :bank_name, :account_bank_number, :account_bank_routing_number, :capacity, :num_of_bathrooms, :min_age, :venue_type, :has_bar, :located, :dress_code, :has_vr, :audio_description, :lighting_description, :stage_description, :address, :lat, :lng)
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
        params.permit(:about)
    end
end
