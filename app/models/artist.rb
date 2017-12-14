class Artist < ApplicationRecord
    has_many :genres, foreign_key: 'artist_id', class_name: 'ArtistGenre'

    has_one :account

    def as_json(options={})
        if options[:extended] == true
            res = super.merge(account.get_attrs)
            res[:genres] = genres
            return res
        else
            return account.get_attrs
        end
    end
end
