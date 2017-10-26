class AddInfoToToken < ActiveRecord::Migration[5.1]
  def change
    add_column :tokens, :info, :string
  end
end
