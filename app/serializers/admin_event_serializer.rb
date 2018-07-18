class AdminEventSerializer < ActiveModel::Serializer
  attributes :id, :name, :date_from, :address, :status, :is_crowdfunding_event, :received_date

  def received_date
    object.created_at
  end
end
