class AccessHelper

	def self.grant_user_access(user)
		@accesses = []
		return grant_access(user, @accesses)
	end


    def self.grant_access(user, access_list)
		user.accesses.clear
		access_list.each do |acc|
			begin
				@acc = Access.find_by name: acc
				user.accesses << @acc
			rescue Exception
				return false
			end
		end
		return true
	end

    def self.check_access(user, access)
        if user != nil 
			return user.has_access?(access)
		end 
		return false
    end

	def self.has_access?(user, access)
		if user != nil
			return user.has_access?(access)
		end
		return false
	end

end