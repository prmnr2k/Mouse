class VenueOperatingHour < ApplicationRecord
    belongs_to :venue
    def as_json(options={})
        res = super
        res
    end
end
