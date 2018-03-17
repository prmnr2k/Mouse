class AcceptMessage < ApplicationRecord
  has_one :inbox_message, foreign_key: :accept_msg_id
end
