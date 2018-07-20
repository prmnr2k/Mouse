class Admin < ApplicationRecord
  belongs_to :user
  belongs_to :image, optional: true
end
