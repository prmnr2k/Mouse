class AddDisplayNameToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :display_name, :string
  end
end
