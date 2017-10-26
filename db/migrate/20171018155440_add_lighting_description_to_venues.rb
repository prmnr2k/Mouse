class AddLightingDescriptionToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :lighting_description, :string
  end
end
