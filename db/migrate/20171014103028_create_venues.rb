class CreateVenues < ActiveRecord::Migration[5.1]
  def change
    create_table :venues do |t|
      t.string :about
      t.string :contact_info
      t.string :address
      t.float :lat
      t.float :lng

      t.timestamps
    end
  end
end
