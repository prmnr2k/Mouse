class Account < ApplicationRecord
	 
	validates :account_type, presence: true

	enum account_type: [:venue, :artist, :fan]

	validates :user_name, presence: true, uniqueness: true, length: {:within => 3..30}

	has_many :images, dependent: :destroy

	has_many :followers_conn, foreign_key: 'to_id', class_name: 'Follower'
	has_many :followers, through: :followers_conn, source: 'to'

	has_many :followings_conn, foreign_key: 'by_id', class_name: 'Follower'
	has_many :following, through: :followings_conn, source: 'by'

	belongs_to :user
	belongs_to :fan, optional: true
	belongs_to :artist, optional: true
	belongs_to :venue, optional: true

	belongs_to :image, optional: true

	has_many :collaborated_events, through: :event_collaborators, class_name: 'Event'
	has_many :events, foreign_key: 'creator_id'
	
    
	def get_attrs
		attrs = {}
		attrs[:id] = id
		attrs[:user_name] = user_name
		attrs[:display_name] = display_name
		attrs[:phone] = phone
		attrs[:created_at] = created_at
		attrs[:updated_at] = updated_at
		attrs[:image_id] = image_id
		attrs[:account_type] = account_type
		return attrs
	end

    def as_json(options={})
      if fan
          _fan = fan.as_json(options)
					_fan[:followers_count] = followers.count
					_fan[:following_count] = following.count
				return _fan
      end

	  	if venue
		  	return venue.as_json(options)
		#   venue_attrs = venue.as_json
		#   venue_attrs.each do |att|
		# 	  attrs[att[0]] = att[1] if not attrs.key?(att[0])
		#   end
      end

	  	if artist
          return artist.as_json(options)
      end

	  #attrs[:genres] = user_genres.pluck(:name)
	  #attrs[:images] = images.pluck(:id)
	  #attrs[:followed] = followed_conn.pluck(:to_id)
	  #attrs[:followers] = followers_conn.pluck(:by_id)
	  return get_attrs
		end

	def self.search(text)
		return self.where(
			"user_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
		).or(
			Account.where("display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
		)
	end
end
