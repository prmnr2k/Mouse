class RequestMessage < ApplicationRecord
  enum time_frame: TimeFrameHelper.all

  has_one :inbox_message, foreign_key: :request_msg_id
end
