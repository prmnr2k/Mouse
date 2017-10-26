class AddHasBarToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :has_bar, :boolean
  end
end
