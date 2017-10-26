class Fan < ApplicationRecord
    has_many :fan_genres, dependent: :destroy
end
