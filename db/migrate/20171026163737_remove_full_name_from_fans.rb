class RemoveFullNameFromFans < ActiveRecord::Migration[5.1]
  def change
    remove_column :fans, :full_name, :string
  end
end
