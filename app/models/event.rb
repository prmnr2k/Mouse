class Event < ApplicationRecord
  belongs_to :creator, class_name: 'Account'

  has_many :event_collaborators, foreign_key: 'event_id'
  has_many :collaborators, through: :event_collaborators, class_name: 'Account'
  # has_many :tickets, foreign_key: 'ticket_id', class_name: 'Ticket'
  has_many :likes, foreign_key: 'event_id', dependent: :destroy

  has_many :genres, foreign_key: 'event_id', class_name: 'EventGenre', dependent: :destroy
  belongs_to :venue, optional: true
  belongs_to :artist, optional: true

  def as_json(options={})
    res = super
    res.delete('artist_id')
    res.delete('venue_id')
    if options[:extended]
      res[:collaborators] = collaborators
      res[:genres] = genres
      res[:artist] = artist
      res[:venue] = venue
      #res[:tickets] = tickets
    elsif options[:analytics]
      res[:location] = venue.address
      #res[:comments] =
      res[:likes] = likes.count
    else
      res[:location] = venue.address
    end
    return res
  end
end
