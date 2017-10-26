class AddAccountBankRoutingNumberToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :account_bank_routing_number, :string
  end
end
