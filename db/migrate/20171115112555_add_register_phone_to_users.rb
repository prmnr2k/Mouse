class AddRegisterPhoneToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :register_phone, :string
  end
end
