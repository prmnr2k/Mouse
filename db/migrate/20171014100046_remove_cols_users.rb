class RemoveColsUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :bio
    remove_column :users, :contacts
    remove_column :users, :address
    remove_column :users, :lat
    remove_column :users, :lng
    remove_column :users, :full_name
  end
end
