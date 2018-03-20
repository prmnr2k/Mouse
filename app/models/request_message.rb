class RequestMessage < ApplicationRecord
  enum time_frame: TimeFrameHelper.all

  belongs_to :inbox_message
end
