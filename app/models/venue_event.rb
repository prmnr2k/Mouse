class VenueEvent < ApplicationRecord
  enum status: StatusHelper.invites

  belongs_to :event
  belongs_to :account, foreign_key: :venue_id
  has_one :agreed_date_time_and_price

  validates_uniqueness_of :event_id, scope: [:venue_id]

  after_initialize :set_defaults

  def set_defaults
    if self.new_record?
      if event.creator.is_verified
        self.status = "ready"
      else
        self.status = "pending"
      end
    end
  end

  def as_json(options={})
    res = super
    res.delete('id')
    res.delete('event_id')
    res.delete('rental_from')
    res.delete('rental_to')

    res[:venue] = account.venue.as_json(for_event: true)

    if ['owner_accepted'].include?(status)
      res[:agreement] = agreed_date_time_and_price
    end

    if status == 'accepted'
      message = account.sent_messages.joins(:accept_message).where(accept_messages: {event: event}).first
      if message
        res['message_id'] = message.id
      end
    elsif status == 'declined'
      message = account.sent_messages.joins(:decline_message).where(decline_messages: {event: event}).first
      if message
        res['reason'] = message.decline_message.reason
        res['reason_text'] = message.decline_message.additional_text
      end
    elsif status == 'owner_declined'
      message = event.creator.sent_messages.joins(:decline_message).where(decline_messages: {event: event}).first
      if message
        res['reason'] = message.decline_message.reason
        res['reason_text'] = message.decline_message.additional_text
      end
    end

    return res
  end
end
