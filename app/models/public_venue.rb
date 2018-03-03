class PublicVenue < ApplicationRecord
  validates_inclusion_of :min_age, in: 0..150, allow_nil: true
  validates_inclusion_of :num_of_bathrooms, in: 0..1000000, allow_nil: true

  enum type_of_space: [:night_club, :concert_hall, :event_space, :theatre, :additional_room,
                    :stadium_arena, :outdoor_space, :other]
  enum located: [:indoors, :outdoors, :other_location]

  belongs_to :venue
  has_many :genres, foreign_key: 'venue_id', class_name: 'VenueGenre'

  def get_attrs
    attrs = {}
    attrs[:fax] = fax
    attrs[:bank_name] = bank_name
    attrs[:account_bank_number] = account_bank_number
    attrs[:account_bank_routing_number] = account_bank_routing_number
    attrs[:num_of_bathrooms] = num_of_bathrooms
    attrs[:min_age] = min_age
    attrs[:has_bar] = has_bar
    attrs[:located] = located
    attrs[:dress_code] = dress_code
    attrs[:audio_description] = audio_description
    attrs[:lighting_description] = lighting_description
    attrs[:stage_description] = stage_description
    return attrs
  end
end
