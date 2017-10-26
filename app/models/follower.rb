class Follower < ApplicationRecord
    belongs_to :by, class_name: 'Account', foreign_key: 'by_id'
    belongs_to :to, class_name: 'Account', foreign_key: 'to_id'
end
