class AddStageDescriptionToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :stage_description, :string
  end
end
