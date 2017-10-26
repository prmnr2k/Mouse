class RenameVenueHourToVenueOfficeHour < ActiveRecord::Migration[5.1]
  def change
    rename_table :venue_hours, :venue_office_hours
  end
end
