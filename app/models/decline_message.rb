class DeclineMessage < ApplicationRecord
  enum reason: [:price, :location, :time, :other]

  has_one :inbox_message, foreign_key: :decline_msg_id
end
