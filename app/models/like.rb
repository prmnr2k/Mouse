class Like < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :event

  validates_uniqueness_of :user_id, :scope => [:event_id]

  def as_json(options={})
    res = super
    if options[:feed]
      res.delete('user_id')
      res.delete('event_id')
      res.delete('account_id')
      res.delete('updated_at')
      res.delete('id')
      res[:event] = event.as_json(only: [:id, :name])
      res[:account] = account.as_json(only: [:id, :user_name, :image_id])
    end
    return res
  end
end
