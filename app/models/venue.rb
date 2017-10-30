class Venue < ApplicationRecord

    validates_inclusion_of :capacity, in: 1..1000000
    validates_inclusion_of :min_age, in: 0..150
    validates_inclusion_of :num_of_bathrooms, in: 0..1000000

    enum venue_type: [:night_club, :concert_hall, :event_space, :theatre, :additional_room,
                     :stadium_arena, :outdoor_space, :private_residence, :other]

    enum located: [:indoors, :outdoors, :other_location]

    has_many :operating_hours, foreign_key: 'venue_id', class_name: 'VenueOperatingHour'
    has_many :office_hours, foreign_key: 'venue_id', class_name: 'VenueOfficeHour'
    has_many :dates, foreign_key: 'venue_id', class_name: 'VenueDate'
    has_many :emails, foreign_key: 'venue_id', class_name: 'VenueEmail'

    has_one :account

    def as_json(options={})
        if options[:extended]
            res = super.merge(account.get_attrs)
            res[:operating_hours] = operating_hours
            res[:office_hours] = office_hours
            res[:dates] = dates
            res[:emails] = emails
            return res
        else
             res = super.merge(account.get_attrs)
            res[:operating_hours] = operating_hours
            res[:office_hours] = office_hours
            res[:dates] = dates
            res[:emails] = emails
            return res
            return account.get_attrs
        end
    end
end
