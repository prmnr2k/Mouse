class Event < ApplicationRecord
  validates_length_of :description, maximum: 500, allow_blank: true

  belongs_to :creator, class_name: 'Account'

  enum event_season: [:spring, :summer, :autumn, :winter]
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
    res.delete('old_date_from')
    res.delete('old_date_to')

    in_person_sold = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'in_person'}).count
    vr_sold = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'vr'}).count


    if options[:fan_ticket]
      res[:in_person_tickets] = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'in_person'}).exists?
      res[:vr_tickets] = tickets.joins(:fan_tickets, :tickets_type).where(tickets_types: {name: 'vr'}).exists?
      res[:tickets_count] = tickets.joins(:fan_tickets).count

      return res
    end

    res[:backers] = tickets.joins(:fan_tickets).pluck(:account_id).uniq.count
    res[:founded] = tickets.joins(:fan_tickets).sum("fan_tickets.price")

    if options[:extended]
      res[:collaborators] = collaborators
      res[:genres] = genres.pluck(:genre)
      res[:artist] = artist_events
      res[:venue] = venue
      res[:venues] = venue_events
      res[:tickets] = tickets
    elsif options[:analytics]
      # res[:location] = venue.address if venue
      res[:comments] = comments.count
      res[:likes] = likes.count
      res[:purchased_tickets] = tickets.joins(:fan_tickets).count
      res[:in_person_tickets_sold] = in_person_sold
      res[:vr_tickets_sold] = vr_sold
    elsif options[:search]
      res[:artists] = artist_events.joins(:account => :artist).where(artist_events: {status: 'active'}).pluck("artists.stage_name")
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
      @events = @events.left_joins(:venue, :artist_events => :account).where(
        "events.name ILIKE :query", query: "%#{sanitize_sql_like(text)}%"
      ).or(
        Event.left_joins(:venue, :artist_events => :account).where("events.tagline ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.left_joins(:venue, :artist_events => :account).where("events.description ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.left_joins(:venue, :artist_events => :account).where("accounts.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      ).or(
        Event.left_joins(:venue, :artist_events => :account).where("accounts_artist_events.display_name ILIKE :query", query: "%#{sanitize_sql_like(text)}%")
      )
    end

    return @events
  end

  def self.get_my(account)
    events = Event.all

    if account.account_type == 'artist'
      events = events.left_joins(:artist_events).where(
        sanitize_sql_for_conditions(["artist_events.artist_id=:id AND artist_events.status=:status",
                                     id: account.id,
                                     status: ArtistEvent.statuses['accepted']])
      ).or(
         Event.left_joins(:artist_events).where(creator_id: account.id)
      )
    elsif account.account_type == 'venue'
      events = events.where(venue_id: account.id).or(Event.where(creator_id: account.id))
    elsif account.account_type == 'fan'
      events = events.where(creator_id: account.id)
    end

    return events
  end
end
