class RemoveContactInfoFromVenues < ActiveRecord::Migration[5.1]
  def change
    remove_column :venues, :contact_info, :string
  end
end
