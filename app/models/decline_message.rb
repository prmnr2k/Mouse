class DeclineMessage < ApplicationRecord
  enum reason: [:price, :location, :time, :other]

  belongs_to :inbox_message
end
