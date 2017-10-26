class User < ApplicationRecord

    validates :email, presence: true, uniqueness: true
	validates :password, presence: true, length: {:within => 6..100} #, confirmation: true

	before_save :encrypt, if: :password_changed?
	validates_confirmation_of :password, message: 'NOT_MATCHED'
	attr_accessor :password_confirmation
	
	validate :check_old, if: :password_changed?, on: :update
	attr_accessor :old_password


    has_many :tokens, dependent: :destroy	
	has_many :accounts, dependent: :destroy
	
	#has_and_belongs_to_many :accesses, dependent: :destroy

    SALT = 'elite_salt'
    
    def self.encrypt_password(password)
		return Digest::SHA256.hexdigest(password + SALT)
	end

	def encrypt 
		self.password = User.encrypt_password(self.password) if self.password
	end

	def check_old 
		errors.add(:old_password, 'NOT_MACHED') if User.find(id).password != User.encrypt_password(self.old_password)
	end

	def has_access?(access_name)
		@access = self.accesses.find{|a| a.name == access_name.to_s}
		return @access != nil ? true : false
	end
end
