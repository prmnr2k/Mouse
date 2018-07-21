class Admin < ApplicationRecord
  belongs_to :user
  belongs_to :image, optional: true

  has_many :processed_users, foreign_key: 'processed_by', class_name: 'Account', dependent: :nullify
end
