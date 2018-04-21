class AddOtherGenreToVenue < ActiveRecord::Migration[5.1]
  def change
    add_column :public_venue, :other_genre_description, :string
  end
end
