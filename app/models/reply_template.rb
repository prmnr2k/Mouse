class ReplyTemplate < ApplicationRecord
  enum status: [:new, :approved]
end
