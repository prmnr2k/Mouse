class AccountVideoLink < ApplicationRecord
  belongs_to :account

  validates :album_name, presence: false
end
