class AddBankNameToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :bank_name, :string
  end
end
