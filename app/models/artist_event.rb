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

    if ['owner_accepted', 'active'].include?(status)
      res[:agreement] = agreed_date_time_and_price
    end

    if status == 'accepted'
      message = account.sent_messages.joins(:accept_message).where(accept_messages: {event: event}).first
      if message
        res['message_id'] = message.id
      end
    end

    return res
  end
end
