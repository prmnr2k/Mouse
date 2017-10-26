class AddVenueTypeToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :venue_type, :integer
  end
end
