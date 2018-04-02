class Event < ApplicationRecord
  validates_length_of :description, maximum: 500, allow_blank: true

  belongs_to :creator, class_name: 'Account'

  enum event_month: [:jan, :feb, :mar, :apr, :may, :jun, :jul, :aug, :sep, :oct, :nov, :dec]
  enum event_time: [:morning, :afternoon, :evening]

  has_many :event_collaborators, foreign_key: 'event_id'
  has_many :collaborators, through: :event_collaborators, class_name: 'Account'

  has_many :venue_events, foreign_key: 'event_id'
  has_many :venues, through: :venue_events, source: :account, class_name: 'Account'

  has_many :artist_events, foreign_key: 'event_id'
  has_many :artists, through: :artist_events, source: :account, class_name: 'Account'

  has_many :request_messages
  has_many :accept_messages
  has_many :decline_messages

  has_many :genres, foreign_key: 'event_id', class_name: 'EventGenre', dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, foreign_key: 'event_id', dependent: :destroy
  has_many :event_updates

  belongs_to :venue, class_name: 'Account', optional: true

  belongs_to :image, optional: true
  has_many :images, dependent: :destroy

  geocoded_by :address, latitude: :city_lat, longitude: :city_lng
  reverse_geocoded_by :city_lat, :city_lng, address: :address
  after_validation :geocode

  def as_json(options={})
    if options[:only]
      return super(options)
    end

    res = super
    res.delete('artist_id')
    res.delete('venue_id')
    res.delete('old_address')
    res.delete('old_city_lat')
    res.delete('old_city_lng')
    res[:backers] = tickets.joins(:fan_tickets).pluck(:account_id).uniq.count
    res[:founded] = tickets.joins(:fan_tickets).sum("fan_tickets.price")

    if options[:extended]
      res[:collaborators] = collaborators
      res[:genres] = genres.pluck(:genre)
      res[:artist] = artist_events
      res[:venue] = venue_events
      res[:tickets] = tickets.as_json(only: [:id, :name, :type])
    elsif options[:analytics]
      # res[:location] = venue.address if venue
      res[:comments] = comments.count
      res[:likes] = likes.count
      res[:purchased_tickets] = tickets.joins(:fan_tickets).count
      res[:in_person_tickets_sold] = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'in_person'}).count
      res[:vr_tickets_sold] = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'vr'}).count
    else
      # res[:location] = venue.address if venue
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
      @events = @events.joins(:venue, :artist_events => :account).where(
        "events.name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
      ).or(
        Event.joins(:venue, :artist_events => :account).where("events.tagline ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:venue, :artist_events => :account).where("events.description ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:venue, :artist_events => :account).where("accounts.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.joins(:venue, :artist_events => :account).where("accounts_artist_events.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      )
    end

    return @events
  end
end
