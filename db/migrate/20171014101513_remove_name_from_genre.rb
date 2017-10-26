class RemoveNameFromGenre < ActiveRecord::Migration[5.1]
  def change
    remove_column :genres, :name, :string
  end
end
