class VenueEvent < ApplicationRecord
  belongs_to :event
  belongs_to :venue

  validates_uniqueness_of :event_id, scope: [:venue_id]
end
