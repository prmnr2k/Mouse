class QuestionReplySerializer < ActiveModel::Serializer
  attributes :id, :subject, :message

  belongs_to :admin
end