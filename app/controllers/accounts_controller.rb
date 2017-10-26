class AccountsController < ApplicationController
    before_action :authorize_user, only: [:create, :get_my_accounts]
    before_action :authorize_account, only: [:update_me, :get_me, :upload_image, :delete_image, :follow, :unfollow]  
    before_action :find_account, only: [:get, :follow, :unfollow, :get_images, :get_followers, :get_followed]  
    before_action :find_image, only: [:delete_image]  

    def show
    end

    # GET /accounts/get/<id>
    def get
        render json: @to_find
    end

    # GET /accounts/get_all
    def get_all
        @accounts = Account.all
        render json: @accounts.limit(params[:limit]).offset(params[:offset])
    end

    # GET /accounts/get_my_accounts
    def get_my_accounts   
       render json: @user.accounts
    end

    # GET /accounts/get_me
    def get_me
        render json: @account
    end

    # GET /accounts/get_images/<id>
    def get_images
        render json: {
            total_count: @to_find.images.count,
            followers: @to_find.images.limit(params[:limit]).offset(params[:offset]).pluck(:to_id)
        }
    end

    #POST /accounts/upload_image
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

    #DELETE /accounts/delete_image/<id>
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

    #POST /accounts/upload_image/<id>
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

    # GET /accounts/get_followers/<id>
    def get_followers 
        render json: {
            total_count: @to_find.followers_conn.count,
            followers: @to_find.followers_conn.limit(params[:limit]).offset(params[:offset]).pluck(:by_id)
        }
    end

    # GET /accounts/get_followed/<id>
    def get_followed
        render json: {
            total_count: @to_find.followed_conn.count,
            followed: @to_find.followed_conn.limit(params[:limit]).offset(params[:offset]).pluck(:to_id)
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

    # POST /accounts/create
    def create
        @account = Account.new(account_create_params)
        @account.user = @user

        if @account.save
            set_image
            set_genres

            set_fan_params
            set_venue_params
            set_artist_params

            @account.save
            #AccessHelper.grant_account_access(@account)
            render json: @account, except: :password, status: :created
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # PUT /accounts/update/<id>
    def update
        set_image
        set_genres
        if @account.update(account_update_params)
            render json: @account, except: :password, status: :ok
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # PUT /accounts/update_me
    def update_me
        set_image
        set_genres

        set_fan_params
        set_venue_params
        set_artist_params
        if @account.update(account_update_params)
            render json: @account, except: :password, status: :ok
        else
            render json: @account.errors, status: :unprocessable_entity
        end
    end

    # DELETE /accounts/1
    def destroy
      @account.destroy
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
        @account = Account.find(params[:account_id])
        render status: :unauthorized if @user == nil or @account.user != @user
    end

    def set_image
        if params[:base64]
            #@account.image.delete if @account.image != nil
            image = Image.new(base64: params[:base64])
            #image.save
            @account.image = image
            @account.images << image
        end
    end

    def set_genres
        if params[:genres]
            @account.account_genres.clear
            params[:genres].each do |genre|
              obj = AccountGenre.new(name: genre)
              obj.save
              @account.account_genres << obj
            end
        end
    end

    def set_fan_params
        if @account.account_type == 'fan'
            if @account.fan 
                @account.fan.update(fan_params)
            else
                fan = Fan.new(fan_params)
                fan.save
                @account.fan = fan
            end
        end
    end

    def set_venue_params
        if @account.account_type == 'venue'
            if @account.venue 
                @account.venue.update(venue_params)
            else
                venue = Venue.new(venue_params)
                venue.save
                @account.venue = venue
            end
        end
    end

    def set_artist_params
        if @account.account_type == 'artist'
            if @account.artist
                @account.artist.update(artist_params)
            else
                artist = Artist.new(artist_params)
                artist.save
                @account.artist = artist
            end
        end
    end

    def account_create_params
        params.permit(:user_name, :phone, :account_type)
    end

    def account_update_params
        params.permit(:user_name, :phone, :account_type)
    end

    def fan_params
        params.permit(:bio, :address, :lat, :lng)
    end

    def venue_params
        params.permit(:about, :contact_info, :address, :lat, :lng)
    end

    def artist_params
        params.permit(:about)
    end
end
