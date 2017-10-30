class AccountsController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:update, :upload_image, :follow, :unfollow]  
    before_action :find_account, only: [:get, :follow, :unfollow, :get_images, :get_followers, :get_followed]  
    before_action :find_image, only: [:delete_image]  


    # GET /accounts/<id>
    def get
        extended = true
        extended = params[:extended] if params[:extended]
        render json: @to_find, extended: extended, status: :ok
    end

    # GET /accounts/
    def get_all
        @accounts = Account.all
        extended = false
        extended = params[:extended] if params[:extended]
        render json: @accounts.limit(params[:limit]).offset(params[:offset]), extended: extended, status: :ok
    end

    # GET /accounts/my
    def get_my_accounts   
       extended = false
       extended = params[:extended] if params[:extended]
       render json: @user.accounts, extended: extended, status: :ok
    end

    # GET /accounts/images/<id>
    def get_images
        render json: {
            total_count: @to_find.images.count,
            images: @to_find.images.limit(params[:limit]).offset(params[:offset]).pluck(:to_id)
        }
    end

    #POST /accounts/images/<id>
    def upload_image
        image = Image.new(base64: params[:image])
        image.account = @account
        if image.save
            @account.images << image
            render json: @account, status: :ok
        else
            render json: image.errors, status: :unprocessable_entity
        end
    end


    #POST /accounts/follow/<id>
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
    def get_followers 
        render json: {
            total_count: @to_find.followers.count,
            followers: @to_find.followers.limit(params[:limit]).offset(params[:offset])
        }
    end

    # GET /accounts/following/<id>
    def get_followed
        render json: {
            total_count: @to_find.following.count,
            following: @to_find.following.limit(params[:limit]).offset(params[:offset])
        }
    end

    #DELETE /accounts/unfollow/<id>
    def unfollow
        follower = Follower.find_by(by_id: @account.id, to_id: @to_find.id)
        if follower 
            follower.destroy
            render status: :ok
        end
    end

    # POST /accounts
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

    # PUT /accounts/<id>
    def update
        set_image
        
        set_fan_params
        set_venue_params
        set_artist_params
        if @account.update(account_params)
            render json: @account, except: :password, status: :ok
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
            image = Image.new(base64: params[:image])
            #image.save
            @account.image = image
            @account.images << image
        end
    end

    def set_fan_params
        if @account.account_type == 'fan'
            if @account.fan 
                @fan = account.fan
                @fan.update(fan_params)
            else
                @fan = Fan.new(fan_params)
                @fan.save
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
                @venue.save
                @account.venue_id = @venue.id
                @account.save
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
            @venue.VenueOfficeHour.clear
            params[:office_hours].each do |hour|
                obj = VenueOfficeHour.new(venue_office_hours_params(hour))
                obj.save
                @venue.office_hours << obj
            end
        end
    end

    def set_venue_operating_hours
        if params[:operating_hours]
            @venue.VenueOperatingHour.clear
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
                @artist.save
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
