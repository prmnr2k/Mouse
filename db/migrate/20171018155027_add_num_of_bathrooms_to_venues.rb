class AddNumOfBathroomsToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :num_of_bathrooms, :integer
  end
end
