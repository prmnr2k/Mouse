class AcceptMessage < ApplicationRecord
  enum currency: CurrencyHelper.all

  belongs_to :inbox_message, dependent: :destroy
  belongs_to :event

  before_save do |message|
    message.currency = message.inbox_message.sender.preferred_currency
  end

  def as_json(options={})
    res = super
    res.delete('id')
    res.delete('event_id')

    res[:event_info] = event
    return res
  end
end
