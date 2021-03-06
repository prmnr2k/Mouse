class FanGenre < ApplicationRecord
    enum genre: GenresHelper.all
	validates :genre, presence: true

    belongs_to :fan

     def as_json(options={})
        res = super
        res.delete('id')
        res.delete('fan_id')
        res.delete('created_at')
        res.delete('updated_at')
        return res
    end
end
