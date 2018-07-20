class Feedback < ApplicationRecord
  enum feedback_type: [:bug, :enhancement, :compliment]

  belongs_to :account
end
