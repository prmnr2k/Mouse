class VenueDate < ApplicationRecord
    belongs_to :venue
    
    enum booking_notice: [:same_day, :one_day, :two_seven_days]
     def as_json(options={})
        res = super
        res.delete('id')
        res.delete('venue_id')
        res.delete('created_at')
        res.delete('updated_at')
        return res
    end
end
