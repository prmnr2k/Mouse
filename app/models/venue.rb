class Venue < ApplicationRecord

    enum venue_type: [:night_club, :concert_hall, :event_space, :theatre, :additional_room,
                     :stadium_arena, :outdoor_space, :private_residence, :other]

    enum located: [:indoors, :outdoors, :other_location]

    has_many :venue_operating_hours
    has_many :venue_office_hours
    has_many :venue_dates
    has_many :venue_emails
end
