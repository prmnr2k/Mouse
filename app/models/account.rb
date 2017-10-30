class Account < ApplicationRecord
	enum account_type: [:fan, :venue, :artist]
	validates :account_type, presence: true

	validates :user_name, presence: true, uniqueness: true, length: {:within => 3..30}

	has_many :images, dependent: :destroy

	has_many :followers_conn, foreign_key: 'to_id', class_name: 'Follower'
	has_many :followers, through: :followers_conn, source: 'to_id'

	has_many :followings_conn, foreign_key: 'by_id', class_name: 'Follower'
	has_many :following, through: :followings_conn, source: 'by_id'

    belongs_to :user
    belongs_to :fan, optional: true
	belongs_to :artist, optional: true
	belongs_to :venue, optional: true

    belongs_to :image, optional: true
    
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
      attrs = super
      if fan
          return fan.as_json(options)
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
end
