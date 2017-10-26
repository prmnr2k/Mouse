class RemoveFullNameFromArtists < ActiveRecord::Migration[5.1]
  def change
    remove_column :artists, :full_name, :string
  end
end
