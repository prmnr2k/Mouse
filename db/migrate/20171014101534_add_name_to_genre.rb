class AddNameToGenre < ActiveRecord::Migration[5.1]
  def change
    add_column :genres, :name, :integer
  end
end
