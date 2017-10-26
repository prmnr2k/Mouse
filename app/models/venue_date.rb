class VenueDate < ApplicationRecord
    belongs_to :venue
    
    enum booking_notice: [:same_day, :one_day, :two_seven_days]
end
