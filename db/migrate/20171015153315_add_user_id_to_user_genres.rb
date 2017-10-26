class AddUserIdToUserGenres < ActiveRecord::Migration[5.1]
  def change
    add_column :user_genres, :user_id, :integer
  end
end
