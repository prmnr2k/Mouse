class ArtistEvent < ApplicationRecord
  enum status: StatusHelper.all

  belongs_to :event
  belongs_to :account, foreign_key: :artist_id
  has_one :agreed_date_time_and_price

  validates_uniqueness_of :event_id, scope: [:artist_id]

  after_initialize :set_defaults

  def set_defaults
    self.status = "pending" if self.new_record?
  end

  def as_json(options={})
    res = super
    res.delete('id')
    res.delete('event_id')

    if status == 'owner_accepted'
      res[:agreement] = agreed_date_time_and_price
    end

    return res
  end
end
