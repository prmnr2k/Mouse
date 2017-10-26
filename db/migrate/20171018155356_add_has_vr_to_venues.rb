class AddHasVrToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :has_vr, :boolean
  end
end
