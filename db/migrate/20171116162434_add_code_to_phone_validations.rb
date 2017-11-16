class AddCodeToPhoneValidations < ActiveRecord::Migration[5.1]
  def change
    add_column :phone_validations, :code, :string
  end
end
