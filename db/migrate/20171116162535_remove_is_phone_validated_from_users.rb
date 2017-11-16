class RemoveIsPhoneValidatedFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :is_phone_validated, :boolean
  end
end
