class Artist < ApplicationRecord
    has_many :artist_genres, dependent: :destroy
end
