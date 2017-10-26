class CreateTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :tokens do |t|
      t.string :token
      t.integer :user_id

      t.timestamps
    end
  end
end
