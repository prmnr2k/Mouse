class AdminEventRevenueSerializer < ActiveModel::Serializer
  attributes :id, :name, :owner, :date_from, :is_crowdfunding_event, :address,
             :total_revenue, :artist_revenue, :venue_revenue, :vr_revenue, :tickets_revenue, :advertising_revenue

  def owner
    if object.creator.fan
      return "#{object.creator.fan.first_name} #{object.creator.fan.last_name}"
    elsif object.creator.artist
      return "#{object.creator.artist.first_name} #{object.creator.artist.last_name}"
    elsif object.creator.venue
      return object.creator.display_name
    end
  end

  def artist_revenue
    object.artist_events.joins(:agreed_date_time_and_price).where(
      status: 'owner_accepted').sum('agreed_date_time_and_prices.price')
  end

  def venue_revenue
    object.venue_events.joins(:agreed_date_time_and_price).where(
      status: 'owner_accepted').sum('agreed_date_time_and_prices.price')
  end

  def tickets_revenue
    0
  end

  def vr_revenue
    0
  end

  def advertising_revenue
    0
  end
end