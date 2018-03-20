class Feedback < ApplicationRecord
  enum feedback_type: [:bug, :enhancement, :compliment]

  belongs_to :user
end
