class InboxMessage < ApplicationRecord
  belongs_to :event
  belongs_to :account, foreign_key: 'receiver_id'

  enum message_type: [:accept, :request, :decline]
  belongs_to :decline_message, foreign_key: :decline_msg_id, optional: true
  belongs_to :accept_message, foreign_key: :accept_msg_id, optional: true
  belongs_to :request_message, foreign_key: :request_msg_id, optional: true

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
