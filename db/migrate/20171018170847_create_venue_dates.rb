class CreateVenueDates < ActiveRecord::Migration[5.1]
  def change
    create_table :venue_dates do |t|
      t.integer :venue_id
      t.date :begin_date
      t.date :end_date
      t.integer :is_available
      t.integer :price
      t.integer :booking_notice

      t.timestamps
    end
  end
end
