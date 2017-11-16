class CreatePhoneValidations < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_validations do |t|
      t.string :phone
      t.boolean :is_validated

      t.timestamps
    end
  end
end
