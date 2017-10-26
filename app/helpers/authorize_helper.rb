class AuthorizeHelper 
    
    def self.authorize(request)
		@tokenstr = request.headers['Authorization']
		@token = Token.find_by token: @tokenstr
        return @token if not @token

		#if not @token.is_valid?
			#@token.destroy
			#return nil
		#end
		return @token.user
	end

end
