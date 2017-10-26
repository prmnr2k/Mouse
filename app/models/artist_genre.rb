class ArtistGenre < ApplicationRecord
    enum genre: [:rock, :pop, :rap, :jazz]
	validates :genre, presence: true

    belongs_to :artist
end
