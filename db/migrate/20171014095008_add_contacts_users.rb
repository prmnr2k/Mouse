class AddContactsUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :contacts, :string
  end
end
