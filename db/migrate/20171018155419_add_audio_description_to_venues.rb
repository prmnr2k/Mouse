class AddAudioDescriptionToVenues < ActiveRecord::Migration[5.1]
  def change
    add_column :venues, :audio_description, :string
  end
end
