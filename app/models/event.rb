class Event < ApplicationRecord
  belongs_to :creator, class_name: 'Account'

  has_many :event_collaborators, foreign_key: 'event_id'
  has_many :collaborators, through: :event_collaborators, class_name: 'Account'
  has_many :tickets, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, foreign_key: 'event_id', dependent: :destroy

  has_many :genres, foreign_key: 'event_id', class_name: 'EventGenre', dependent: :destroy
  belongs_to :venue, optional: true
  belongs_to :artist, optional: true

  def as_json(options={})
    res = super
    res.delete('artist_id')
    res.delete('venue_id')
    res[:backers] = tickets.joins(:fan_tickets).pluck(:fan_id).uniq.count
    res[:founded] = tickets.joins(:fan_tickets).sum("fan_tickets.price")

    if options[:extended]
      res[:collaborators] = collaborators
      res[:genres] = genres
      res[:artist] = artist
      res[:venue] = venue  
      res[:tickets] = tickets.as_json(only: [:name, :type])
    elsif options[:analytics]
      if venue
        res[:location] = venue.address
      end
      res[:comments] = comments.count
      res[:likes] = likes.count
    else
      res[:location] = venue.address if venue
    end
    return res
  end

  def self.simple_search(text)
    @events = Event.all
    if text
      @events = @events.where(
        "events.name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
      )
    end

    return @events
  end

  def self.search(text="")
    @events = Event.all

    if text
      @events = @events.joins(:artist => :account, :venue => :account).where(
        "events.name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
      ).or(
        Event.joins(:artist => :account, :venue => :account).where("events.tagline ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:artist => :account, :venue => :account).where("events.description ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:artist => :account, :venue => :account).where("accounts.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:artist => :account, :venue => :account).where("accounts_venues.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      )
    end

    return @events
  end
end
