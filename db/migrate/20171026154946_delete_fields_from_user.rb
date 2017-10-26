class DeleteFieldsFromUser < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :user_name, :string
    remove_column :users, :image_id, :integer
    remove_column :users, :phone, :string
    remove_column :users, :fan_id, :integer
    remove_column :users, :artist_id, :integer
    remove_column :users, :venue_id, :integer
    remove_column :users, :account_type, :integer
  end
end
