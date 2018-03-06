class StatusHelper
  def self.all
    return [:pending, :invite_send, :request_send, :accepted, :declined, :owner_accepted, :owner_declined, :time_expired]
  end
end