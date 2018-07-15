class Account < ApplicationRecord
	actable

	enum status: StatusHelper.accounts
	validates :user_name, presence: true, uniqueness: true, length: {:within => 3..30}

	belongs_to :user
	belongs_to :image, optional: true

	has_many :images, dependent: :destroy
	has_many :events, foreign_key: 'creator_id'
	has_many :likes
	has_many :account_updates
	has_many :sent_messages, foreign_key: 'sender_id', class_name: 'InboxMessage'
	has_many :inbox_messages, foreign_key: 'receiver_id', class_name: 'InboxMessage'

	has_many :followers_conn, foreign_key: 'to_id', class_name: 'Follower', dependent: :destroy
	has_many :followers, through: :followers_conn, source: 'by'

	has_many :followings_conn, foreign_key: 'by_id', class_name: 'Follower', dependent: :destroy
	has_many :following, through: :followings_conn, source: 'to'

	has_many :event_collaborators, foreign_key: :collaborator_id
	has_many :collaborated, through: :event_collaborators, source: :event, class_name: 'Event'

	def get_attrs
		attrs = {}
		attrs[:id] = id
		attrs[:user_name] = user_name
		attrs[:display_name] = display_name
		attrs[:phone] = phone
		attrs[:created_at] = created_at
		attrs[:updated_at] = updated_at
		attrs[:image_id] = image_id
		attrs[:followers_count] = followers.count
		attrs[:following_count] = following.count
		return attrs
	end

	def self.search(text)
		return self.where(
			"accounts.user_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
		).or(
			Account.where("accounts.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
		)
	end
end
