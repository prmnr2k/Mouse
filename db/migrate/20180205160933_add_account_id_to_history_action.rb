class AddAccountIdToHistoryAction < ActiveRecord::Migration[5.1]
  def change
    add_column :history_actions, :account_id, :integer
  end
end
