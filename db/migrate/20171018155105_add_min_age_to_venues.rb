class AddMinAgeToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :min_age, :integer
  end
end
