require 'digest'
require 'securerandom'
require 'httparty'
require 'twitter'

require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class AuthenticateController < ApplicationController
	swagger_controller :auth, "Authentification"
	
	# POST /auth/login
	swagger_api :login do
		summary "Authorize by username and password"
		param :form, :user_name, :string, :optional, "Username"
		param :form, :email, :string, :optional, "Email"
		param :form, :password, :password, :required, "Password"
		response :unauthorized
	end
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
		render json: {token: token.token} , status: :ok

	end

	# POST /auth/login_vk
	swagger_api :login_vk do
		summary "Authorize by VK"
		param :form, :access_token, :string, :required, "Access token returned from VK"
		response :unauthorized
	end
	def login_vk
		begin
			@vk = VkontakteApi::Client.new(params[:access_token])
			uid = @vk.users.get[0].uid
		rescue => ex
			render status: :unauthorized and return
		end

		@user = User.find_by(vk_id: uid)
		if not @user
			@user = User.new(vk_id: uid)
			if not @user.save(validate: false)
				render status: :unauthorized and return
			end
		end

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: token.token} , status: :ok
	end

	# POST /auth/login_google
	swagger_api :login_google do
		summary "Authorize by google"
		param :form, :authorization_code, :string, :required, "Code returned by authorization from google"
		response :unauthorized
	end
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
			@user = User.new(google_id: data['id'])
			if not @user.save(validate: false)
				render status: :unauthorized and return
			end
		end

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: token.token} , status: :ok
	end

	# POST /auth/login_twitter
	swagger_api :login_twitter do
		summary "Authorize by twitter"
		param :form, :access_token, :string, :required, "Access token from twitter"
		param :form, :access_token_secret, :string, :required, "Access token secret from twitter"
		response :unauthorized
	end
	def login_twitter
		
		client = Twitter::REST::Client.new do |config|
			config.consumer_key        = 'TVm4kOpBBBjRwyCa9gAJ6SGzn'
			config.consumer_secret     = '7t6Yq20UCEBoJKTmwrNFMItoglFvCxWRQXx31LUqd7BO3dWGgY'
			config.access_token        = params[:access_token]
			config.access_token_secret = params[:access_token_secret]
		end
		@user = User.find_by(twitter_id: client.user.id)

		if not @user
			@user = User.new(twitter_id: client.user.id)
			if not @user.save(validate: false)
				render status: :unauthorized and return
			end
		end

		token = AuthenticateHelper.process_token(request, @user)
		render json: {token: token.token} , status: :ok
	end

	# POST /auth/login_facebook
	swagger_api :login_facebook do
		summary "Authorize by facebook"
		response :unauthorized
	end
	def login_facebook
		
	end

	# POST /auth/logout
	swagger_api :logout do
		summary "Logout"
		param :header, 'Authorization', :string, :required, 'Authentication token'
		response :bad_request
	end
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
