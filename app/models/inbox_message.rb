class InboxMessage < ApplicationRecord
  belongs_to :event
  belongs_to :account, foreign_key: 'receiver_id'

  enum message_type: [:accept, :request, :decline]
  has_one :decline_message
  has_one :accept_message
  has_one :request_message

  def as_json(options={})
    res = super
    res.delete('event_id')
    res.delete('request_msg_id')
    res.delete('accept_msg_id')
    res.delete('decline_msg_id')

    if options[:extended]
      res[:event] = event

      if request_message
        res[:message_info] = request_message
      elsif accept_message
        res[:message_info] = accept_message
      elsif decline_message
        res[:message_info] = decline_message
      end
    end

    return res
  end
end
