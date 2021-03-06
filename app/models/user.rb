class User < ApplicationRecord

	validates :email, presence: true, uniqueness: true
	validates :register_phone, uniqueness: true, allow_nil: true
	validates :password, length: {:within => 6..100}, :allow_blank => true #, confirmation: true

	before_save :encrypt, if: :password_changed?
	validates_confirmation_of :password, message: 'NOT_MATCHED'
	attr_accessor :password_confirmation
	
	validate :check_old, if: :password_changed?, on: :update
	attr_accessor :old_password

	has_many :tokens, dependent: :destroy
	has_many :accounts, dependent: :destroy
	has_many :likes, dependent: :destroy

	belongs_to :image, optional: true

	has_one :admin

	#has_and_belongs_to_many :accesses, dependent: :destroy

    SALT = 'elite_salt'
    
    def self.encrypt_password(password)
		return Digest::SHA256.hexdigest(password + SALT)
	end

	def encrypt 
		self.password = User.encrypt_password(self.password) if self.password
	end

	def check_old
		if self.old_password != nil
			errors.add(:old_password, 'NOT_MACHED') if User.find(id).password != User.encrypt_password(self.old_password)
		end
	end

	def has_access?(access_name)
		@access = self.accesses.find{|a| a.name == access_name.to_s}
		return @access != nil ? true : false
	end
end
