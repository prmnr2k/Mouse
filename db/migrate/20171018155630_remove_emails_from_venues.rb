class RemoveEmailsFromVenues < ActiveRecord::Migration[5.1]
  def change
    remove_column :venues, :emails, :text
  end
end
