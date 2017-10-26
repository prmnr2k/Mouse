class AddAccountBankNumberToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :account_bank_number, :string
  end
end
