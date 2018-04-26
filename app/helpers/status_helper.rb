class StatusHelper
  def self.all
    return [:ready, :pending, :invite_send, :request_send, :accepted, :declined,
            :owner_accepted, :owner_declined, :active, :time_expired]
  end
end