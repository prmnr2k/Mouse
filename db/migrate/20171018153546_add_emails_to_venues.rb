class AddEmailsToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :emails, :text
  end
end
