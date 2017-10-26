class AddUserNameToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :user_name, :string
  end
end
