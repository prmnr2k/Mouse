class RequestMessage < ApplicationRecord
  enum time_frame: TimeFrameHelper.all

  belongs_to :inbox_message, dependent: :destroy
  belongs_to :event
  belongs_to :artist_event, optional: true
  belongs_to :venue_event, optional: true

  def as_json(options={})
    res = super
    res.delete('id')
    res.delete('event_id')

    res[:event_info] = event

    if res.created_at + TimeFrameHelper.to_seconds(res.time_frame) < DateTime.now
      res[:status] = 'time_expired'
    else
      res[:status] = 'valid'
    end
    return res
  end
end
