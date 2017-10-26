class CreateFans < ActiveRecord::Migration[5.1]
  def change
    create_table :fans do |t|
      t.string :full_name
      t.string :bio
      t.string :address
      t.float :lat
      t.float :lng

      t.timestamps
    end
  end
end
