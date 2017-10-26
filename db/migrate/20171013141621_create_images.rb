class CreateImages < ActiveRecord::Migration[5.1]
  def change
    create_table :images do |t|
      t.string :base64
      t.integer :user_id

      t.timestamps
    end
  end
end
