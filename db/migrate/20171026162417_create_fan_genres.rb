class CreateFanGenres < ActiveRecord::Migration[5.1]
  def change
    create_table :fan_genres do |t|
      t.integer :fan_id
      t.integer :genre

      t.timestamps
    end
  end
end
