class EventGenre < ApplicationRecord
  enum genre: [:rock, :pop, :rap, :jazz]

  belongs_to :event

  def as_json(options={})
    res = super
    res.delete('id')
    res.delete('event_id')
    res.delete('created_at')
    res.delete('updated_at')
    return res
  end
end
