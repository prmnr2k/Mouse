class RenameUserIdToAccountIdImages < ActiveRecord::Migration[5.1]
  def change
    rename_column :images, :user_id, :account_id
  end
end
