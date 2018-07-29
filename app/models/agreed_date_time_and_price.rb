class AgreedDateTimeAndPrice < ApplicationRecord
  enum currency: CurrencyHelper.all

  belongs_to :artist_event, optional: true
  belongs_to :venue_event, optional: true

  before_save do |agreement|
    if agreement.artist_event
      agreement.currency = agreement.artist_event.event.currency
    elsif agreement.venue_event
      agreement.currency = agreement.venue_event.event.currency
    end
  end
end
