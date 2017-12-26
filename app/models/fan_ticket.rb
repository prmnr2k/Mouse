class FanTicket < ApplicationRecord
  belongs_to :fan
  belongs_to :ticket
end
