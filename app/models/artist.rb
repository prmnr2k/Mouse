class Artist < ApplicationRecord
    has_many :genres, foreign_key: 'artist_id', class_name: 'ArtistGenre'

    has_one :account
    has_many :audio_links
    has_many :artist_albums
    has_many :artist_riders
    has_many :artist_preferred_venues
    has_many :available_dates, foreign_key: 'artist_id', class_name: ArtistDate
    has_many :artist_videos

    geocoded_by :preferred_address, latitude: :lat, longitude: :lng
    reverse_geocoded_by :lat, :lng, address: :preferred_address
    after_validation :geocode

    def as_json(options={})
        if options[:extended]
            res = super.merge(account.get_attrs)
            res[:genres] = genres.pluck(:genre)
            res[:audio_links] = audio_links
            res[:videos] = artist_videos
            res[:artist_albums] = artist_albums

            if is_hide_pricing_from_profile and not options[:my]
                res.delete('price_from')
                res.delete('price_to')
                res.delete('additional_hours_price')
            end

            if options[:my]
                res[:available_dates] = available_dates
                res[:events_dates] = account.artist_events.joins(:event).where(
                  artist_events: {status: [ArtistEvent.statuses['owner_accepted'], ArtistEvent.statuses['active']]},
                  events: {is_active: true}
                ).as_json(dates: true)
                res[:artist_riders] = artist_riders
                res[:preferred_venues] = artist_preferred_venues
            end

            return res
        else
            attrs = account.get_attrs
          attrs[:first_name] = first_name
          attrs[:last_name] = last_name
          return attrs
        end
    end
end
