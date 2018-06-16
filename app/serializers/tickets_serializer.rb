class TicketsSerializer < ActiveModel::Serializer
  attributes :name, :description, :price, :count, :is_for_personal_use,
             :event_id, :video, :is_promotional, :promotional_description, :type

  def type
    object.tickets_type.name
  end
end
