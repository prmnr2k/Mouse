class VenueDate < ApplicationRecord
  belongs_to :venue

  validates_uniqueness_of :date, scope: [:venue_id]

  def as_json(options = {})
    res = super
    res.delete('venue_id')
    res.delete('created_at')
    res.delete('updated_at')
    return res
  end
end
