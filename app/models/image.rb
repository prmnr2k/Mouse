class Image < ApplicationRecord
    belongs_to :account, optional: true
    belongs_to :event, optional: true
end
