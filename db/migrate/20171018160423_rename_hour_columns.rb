class RenameHourColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :venue_operating_hours, :user_id, :venue_id
    rename_column :venue_office_hours, :user_id, :venue_id
  end
end
