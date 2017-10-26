class AddPhoneToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :phone, :string
  end
end
