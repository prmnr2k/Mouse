class RemoveAboutFromVenues < ActiveRecord::Migration[5.1]
  def change
    remove_column :venues, :about, :string
  end
end
