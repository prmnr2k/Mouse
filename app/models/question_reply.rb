class QuestionReply < ApplicationRecord
  belongs_to :question
  belongs_to :admin
end
