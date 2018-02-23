class Venue < ApplicationRecord

    validates_inclusion_of :capacity, in: 1..1000000, allow_nil: true

    enum venue_type: [:night_club, :concert_hall, :event_space, :theatre, :additional_room,
                     :stadium_arena, :outdoor_space, :private_residence, :other]

    has_many :operating_hours, foreign_key: 'venue_id', class_name: 'VenueOperatingHour'
    has_many :office_hours, foreign_key: 'venue_id', class_name: 'VenueOfficeHour'
    has_many :dates, foreign_key: 'venue_id', class_name: 'VenueDate'
    has_many :emails, foreign_key: 'venue_id', class_name: 'VenueEmail'

    has_one :account
    has_one :public_venue

    def as_json(options={})
        if options[:extended]
            res = super.merge(account.get_attrs)
            if public_venue
                res = res.merge(public_venue.get_attrs)
            end

            res[:operating_hours] = operating_hours
            res[:office_hours] = office_hours
            res[:dates] = dates
            res[:emails] = emails
            return res
        else
            return account.get_attrs
        end
    end
end
