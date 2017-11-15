class AddIsPhoneValidatedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :is_phone_validated, :boolean
  end
end
