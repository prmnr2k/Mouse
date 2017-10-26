class AddFaxToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :fax, :string
  end
end
