class Artist < ApplicationRecord
    has_many :genres, foreign_key: 'artist_id', class_name: 'ArtistGenre'

    has_one :account
    has_many :events
    has_many :audio_links

    geocoded_by :address, latitude: :lat, longitude: :lng
    reverse_geocoded_by :lat, :lng, address: :address
    after_validation :geocode

    def as_json(options={})
        if options[:extended]
            res = super.merge(account.get_attrs)
            res[:genres] = genres.pluck(:genre)
            res[:audio_links] = audio_links.pluck(:audio_link)
            return res
        else
            return account.get_attrs
        end
    end
end
