class AddActableToAccounts < ActiveRecord::Migration[5.1]
  def change
    change_table :accounts do |t|
      t.actable
    end

    remove_column :accounts, :artist_id, :integer
    remove_column :accounts, :venue_id, :integer
    remove_column :accounts, :fan_id, :integer
    remove_column :accounts, :account_type, :integer
    remove_column :accounts, :is_verified, :integer

    remove_column :artists, :created_at, :datetime
    remove_column :venues, :created_at, :datetime
    remove_column :fans, :created_at, :datetime

    remove_column :artists, :updated_at, :datetime
    remove_column :venues, :updated_at, :datetime
    remove_column :fans, :updated_at, :datetime
  end
end
