class ArtistRider < ApplicationRecord
  enum rider_type: [:stage, :backstage, :hospitality, :technical]

  belongs_to :artist

  has_attached_file :uploaded_file
  validates_attachment :uploaded_file, presence: true
end
