class VenueEvent < ApplicationRecord
  belongs_to :event
  belongs_to :account, foreign_key: :venue_id

  validates_uniqueness_of :event_id, scope: [:venue_id]
end
