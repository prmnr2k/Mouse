class CreateVenueOperatingHours < ActiveRecord::Migration[5.1]
  def change
    create_table :venue_operating_hours do |t|
      t.integer :user_id
      t.integer :day
      t.time :begin_time
      t.time :end_time

      t.timestamps
    end
  end
end
