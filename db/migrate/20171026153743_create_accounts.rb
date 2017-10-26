class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      t.integer :image_id
      t.string :phone
      t.integer :fan_id
      t.integer :artist_id
      t.integer :venue_id
      t.integer :account_type
      t.integer :user_id

      t.timestamps
    end
  end
end
