class AdminEventSerializer < ActiveModel::Serializer
  attributes :id, :name, :date_from, :address, :status, :is_crowdfunding_event, :received_date, :denied_by

  def received_date
    object.created_at
  end

  def denied_by
    if object.denier
      object.denier.user_name
    else
      nil
    end
  end
end
