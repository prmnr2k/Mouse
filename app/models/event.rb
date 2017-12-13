class Event < ApplicationRecord
  belongs_to :creator, class_name: 'Account'

  has_many :event_collaborators, foreign_key: 'event_id'
  has_many :collaborators, through: :event_collaborators, class_name: 'Account'
  # has_many :tickets, foreign_key: 'ticket_id', class_name: 'Ticket'

  has_many :genres, foreign_key: 'event_id', class_name: 'EventGenre'
  belongs_to :venue, optional: true
  belongs_to :artist, optional: true

  def as_json(options={})
    res = super
    res[:genres] = genres
    res[:collaborators] = collaborators
    return res
  end
end
