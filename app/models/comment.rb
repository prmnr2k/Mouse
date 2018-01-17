class Comment < ApplicationRecord
  belongs_to :event
  belongs_to :fan

  def as_json(options={})
    res = super
    res.delete('fan_id')

    res[:fan] = fan.as_json(only: [:image_id, :user_name])

    return res
  end
end
