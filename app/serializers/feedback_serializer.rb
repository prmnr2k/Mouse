class FeedbackSerializer < ActiveModel::Serializer
  attributes :id, :feedback_type, :rate_score, :created_at, :detail

  belongs_to :account
end