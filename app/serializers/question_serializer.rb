class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :subject, :message

  belongs_to :account
  has_one :question_reply
end