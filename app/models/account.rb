class Account < ApplicationRecord
	enum account_type: [:fan, :venue, :artist]
	validates :account_type, presence: true

	validates :user_name, presence: true, uniqueness: true, length: {:within => 3..30}

	has_many :images, dependent: :destroy

	has_many :followers_conn, foreign_key: 'to_id', class_name: 'Follower'
	has_many :followers, through: :followers_conn, source: 'to_id'

	has_many :followings_conn, foreign_key: 'by_id', class_name: 'Follower'
	has_many :followings, through: :followings_conn, source: 'by_id'

    belongs_to :user
    belongs_to :fan, optional: true
	belongs_to :artist, optional: true
	belongs_to :venue, optional: true

    belongs_to :image, optional: true
    
    def as_json(options={})
      attrs = super
      if fan
          attrs[:bio] = fan.bio
          attrs[:address] = fan.address
		  attrs[:lat] = fan.lat
		  attrs[:lng] = fan.lng
      end

	  if venue
          attrs[:about] = venue.about
          attrs[:contact_info] = venue.contact_info
          attrs[:address] = venue.address
		  attrs[:lat] = venue.lat
		  attrs[:lng] = venue.lng
      end

	  if artist
          attrs[:full_name] = artist.full_name
          attrs[:about] = artist.about
      end

	  #attrs[:genres] = user_genres.pluck(:name)
	  #attrs[:images] = images.pluck(:id)
	  #attrs[:followed] = followed_conn.pluck(:to_id)
	  #attrs[:followers] = followers_conn.pluck(:by_id)

	  attrs.delete(:password.to_s)
	  attrs.delete(:fan_id.to_s)
	  attrs.delete(:venue_id.to_s)
	  attrs.delete(:artist_id.to_s)
      attrs.delete(:user_id.to_s)
	  return attrs
	end
end
