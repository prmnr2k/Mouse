class Question < ApplicationRecord
  validates :subject, presence: true
  validates :message, presence: true

  belongs_to :account
  belongs_to :question_reply, foreign_key: 'message_id', class_name: 'InboxMessage', optional: true
end
