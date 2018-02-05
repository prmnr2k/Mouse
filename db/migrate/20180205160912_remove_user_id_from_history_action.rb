class RemoveUserIdFromHistoryAction < ActiveRecord::Migration[5.1]
  def change
    remove_column :history_actions, :user_id, :integer
  end
end
