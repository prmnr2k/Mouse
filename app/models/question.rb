class Question < ApplicationRecord
  belongs_to :account
  has_one :question_reply
end
