class FanTicket < ApplicationRecord
  belongs_to :account
  belongs_to :ticket

  def as_json(options={})
    res = super

    if options[:with_tickets]
      res.delete('ticket_id')
      res[:ticket] = ticket
    end

    return res
  end
end
