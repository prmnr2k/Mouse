class CreateVenueEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :venue_emails do |t|
      t.integer :venue_id
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
