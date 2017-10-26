class CreateFollowers < ActiveRecord::Migration[5.1]
  def change
    create_table :followers do |t|
      t.integer :by
      t.integer :user

      t.timestamps
    end
  end
end
