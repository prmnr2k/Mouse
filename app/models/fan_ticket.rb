class FanTicket < ApplicationRecord
  enum currency: CurrencyHelper.all

  belongs_to :account
  belongs_to :ticket

  before_save do |ticket|
    ticket.currency = ticket.account.preferred_currency
  end

  def as_json(options={})
    res = super

    if options[:with_tickets]
      res.delete('ticket_id')

      res[:tickets_left] = ticket.count - FanTicket.where(ticket_id: ticket.id).count
      res[:ticket] = ticket
    end

    return res
  end
end
