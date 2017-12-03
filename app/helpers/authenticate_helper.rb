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

end
