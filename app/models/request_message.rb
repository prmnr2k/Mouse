class RequestMessage < ApplicationRecord
  enum time_frame: TimeFrameHelper.all

  belongs_to :event
  belongs_to :account, foreign_key: 'receiver_id'

  def as_json(options={})
    res = super
    res.delete('event_id')
    res[:event_name] = event.name

    if options[:extended]
      res[:event] = event
    end

    return res
  end
end
