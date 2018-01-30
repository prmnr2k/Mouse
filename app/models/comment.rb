class Comment < ApplicationRecord
  belongs_to :event
  belongs_to :account

  def as_json(options={})
    res = super
    res.delete('account_id')

    res[:fan] = account.fan.as_json(only: [:image_id, :user_name])

    return res
  end
end
