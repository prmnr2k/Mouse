class AddColsUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :fan_id, :integer
    add_column :users, :artist_id, :integer
    add_column :users, :venue_id, :integer
    add_column :users, :account_type, :integer
  end
end
