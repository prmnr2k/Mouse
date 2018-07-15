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
			user = AuthorizeHelper.authorize(request)
      return user
		end

		def self.authorize_and_get_account(request, id)
			user = authorize_and_get_user(request)

			account = Account.find(id)
			if user == nil or account.user != user
				return nil
      else
        return account
			end
		end

		def self.authorized?(account)
			if request.headers['Authorization']
				user = AuthorizeHelper.authorize(request)
				return (user != nil and user == account.user)
			end
		end

end
