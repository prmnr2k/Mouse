class AddDescriptionToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :description, :string
  end
end
