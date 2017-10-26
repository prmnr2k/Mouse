class AddLocatedToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :located, :integer
  end
end
