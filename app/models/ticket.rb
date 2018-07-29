class Ticket < ApplicationRecord
  enum currency: CurrencyHelper.all
  belongs_to :event

  has_one :tickets_type

  has_many :fan_tickets

  before_save do |ticket|
    ticket.currency = ticket.event.currency
  end

  def as_json(options={})
    res = super
    res[:type] = tickets_type ? tickets_type.name : nil
    return res
  end
end
