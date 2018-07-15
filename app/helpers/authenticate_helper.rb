class AuthenticateHelper
    
    SALT = 'kek salt'

    def self.process_token(request, user)
		if request.ip and request.user_agent
			info = Digest::SHA256.hexdigest(request.ip + request.user_agent + SALT) 
		else
			info = SecureRandom.hex
		end
		token = user.tokens.find{|s| s.info == info}
        token.destroy if token
       
        token = Token.new(user_id: user.id, info: info)
		token.save
        return token
		end

		def self.authorize_and_get_user(request)
			@user = AuthorizeHelper.authorize(request)

			if @user == nil
				render status: :unauthorized and return
			end
		end

		def self.authorize_and_get_account(request, field_name)
			authorize_and_get_user(request)
			unless performed?
				render status: :unauthorized and return
			end

			@account = Account.find(params[field_name])
			if @user == nil or @account.user != @user
				render status: :unauthorized and return
			end
		end

end
