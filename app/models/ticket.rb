class Ticket < ApplicationRecord
  belongs_to :event

  has_one :tickets_type
  has_one :tickets_category

  has_many :fan_tickets

  def as_json(options={})
    res = super
    res[:type] = tickets_type ? tickets_type.name : nil
    res[:category] = tickets_category ? tickets_category.name : nil
    return res
  end
end
