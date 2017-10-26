class RenameFollowColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :followers, :by, :by_id
    rename_column :followers, :user, :to_id

  end
end
