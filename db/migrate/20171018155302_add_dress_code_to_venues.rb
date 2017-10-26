class AddDressCodeToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :dress_code, :string
  end
end
