class RenameGenres < ActiveRecord::Migration[5.1]
  def change
      rename_table :genres, :user_genres
  end
end
