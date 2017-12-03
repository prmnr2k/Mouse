require 'digest'
require 'securerandom'
require 'httparty'
require 'twitter'

require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class AuthenticateController < ApplicationController
	
	# POST /auth/login
	def login
		@password = User.encrypt_password(params[:password])
		if params[:user_name]
			@account = Account.find_by(user_name: params[:user_name])
			render status: :unauthorized and return if not @account
			@user = @account.user
		else
			@user = User.find_by(email: params[:email])
			render status: :unauthorized and return if not @user
		end
		render status: :unauthorized and return if @user.password != @password

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: @oken.token} , status: :ok

	end

	# POST /auth/login_google
	def login_google
		client_secret = "LAEUpegdYyAZX3wFeyASBykl"
		client_id = "844170394110-cms890g4tkp36jhbapec4eo7e6n3urt2.apps.googleusercontent.com"
		response = HTTParty.post("https://www.googleapis.com/oauth2/v4/token",
									headers: {'Content-Type': 'application/x-www-form-urlencoded'},
									body: {
										'client_id': client_id,
										'client_secret': client_secret,
										'grant_type': 'authorization_code',
										'redirect_uri': 'http://localhost',
										'code': params[:authorization_code]
									}
								)								
		render status: :unauthorized and return if response.code != 200

		data = JSON.parse(response.body)
		response = HTTParty.get('https://www.googleapis.com/oauth2/v2/userinfo',
									headers: {Access_token: data['access_token'],
									Authorization: "OAuth #{data['access_token']}"})
		render status: :unauthorized and return if response.code != 200

		data = JSON.parse(response.body)

		@user = User.find_by(google_id: data['id'])
		if not @user
			fan = Fan.new(full_name: data['name'])
			fan.save
			@user = User.new(google_id: data['id'])
			if not @user.save(validate: false)
				render status: :unauthorized and return
			end
		end

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: token.token} , status: :ok
	end

	# POST /auth/login_twitter
	def login_twitter
		
		client = Twitter::REST::Client.new do |config|
			config.consumer_key        = 'TVm4kOpBBBjRwyCa9gAJ6SGzn'
			config.consumer_secret     = '7t6Yq20UCEBoJKTmwrNFMItoglFvCxWRQXx31LUqd7BO3dWGgY'
			config.access_token        = params[:access_token]
			config.access_token_secret = params[:access_token_secret]
		end
		@user = User.find_by(twitter_id: client.user.id)

		if not @user
			fan = Fan.new(full_name: client.user.name)
			fan.save
			@user = User.new(twitter_id: client.user.id)
			if not @user.save(validate: false)
				render status: :unauthorized and return
			end
		end

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: token.token} , status: :ok
	end

	# POST /auth/login_facebook
	def login_facebook
		
	end

	# POST /auth/logout
	def logout
		@token = Token.find_by token: request.headers['Authorization']
		if @token != nil
			@token.destroy
			render status: :ok
		else
			render status: :bad_request
		end
	end
end
