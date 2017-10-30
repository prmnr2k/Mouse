class VenuesController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:update_me, :get_me, :upload_image, :delete_image, :follow, :unfollow]  
    before_action :find_account, only: [:get, :follow, :unfollow, :get_images, :get_followers, :get_followed]  
    before_action :find_image, only: [:delete_image]  

    # GET /venues/get/<id>
    def get
        render json: @to_find
    end

    # GET /venues/get_all
    def get_all
        @venues = Venue.all
        render json: @venues.limit(params[:limit]).offset(params[:offset])
    end

    # GET /venues/get_images/<id>
    def get_images
        render json: {
            total_count: @to_find.images.count,
            followers: @to_find.images.limit(params[:limit]).offset(params[:offset]).pluck(:to_id)
        }
    end

    #POST /venues/upload_image
    def upload_image
        image = Image.new(base64: params[:base64])
        image.account = @account
        if image.save
            @account.images << image
            render json: @account, status: :ok
        else
            render json: image.errors, status: :unprocessable_entity
        end
    end

    #DELETE /venues/delete_image/<id>
    def delete_image
        if @image.account == @account
            @account.image = nil if @image == @account.image
            @image.destroy
            @account.save
            render json: @account, status: :ok
        else
            render status: :forbidden
        end
    end

    #POST /venues/upload_image/<id>
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

    # GET /venues/get_followers/<id>
    def get_followers 
        render json: {
            total_count: @to_find.followers_conn.count,
            followers: @to_find.followers_conn.limit(params[:limit]).offset(params[:offset]).pluck(:by_id)
        }
    end

    # GET /venues/get_followed/<id>
    def get_followed
        render json: {
            total_count: @to_find.followed_conn.count,
            followed: @to_find.followed_conn.limit(params[:limit]).offset(params[:offset]).pluck(:to_id)
        }
    end

    #DELETE /venues/unfollow/<id>
    def unfollow
        follower = Follower.find_by(by_id: @account.id, to_id: @to_find.id)
        if follower 
            follower.destroy
            render status: :ok
        end
    end

    # POST /venues/create
    def create
        @account = Account.new(account_params)
        @account.user = @user

        if @account.save
            set_image
            set_venue_params

            @account.save
            #AccessHelper.grant_account_access(@account)
            render json: @account, except: :password, status: :created
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # PUT /venues/update/<id>
    def update
        set_image
        set_venue_params
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
        @image = Image.find(params[:id])
    end

    def authorize_user
        @user = AuthorizeHelper.authorize(request)
        render status: :unauthorized if @user == nil
    end

    def authorize_account
        @user = AuthorizeHelper.authorize(request)
        @account = Account.find(params[:venue_id])
        render status: :unauthorized if @user == nil or @account.user != @user
    end

    def set_image
        if params[:image]
            #@account.image.delete if @account.image != nil
            image = Image.new(image: params[:image])
            image.save
            @account.image = image
            @account.images << image
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
                @account.venue = @venue
            end
        end
    end

    def set_venue_dates
        if params[:dates]
            @venue.dates.clear
            params[:dates].each do |date|
                obj = VenueDate.new(venue_date_params(date))
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

    def account_params
        params.permit(:user_name, :phone, :account_type)
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
