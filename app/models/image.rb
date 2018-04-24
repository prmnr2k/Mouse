class Image < ApplicationRecord
    belongs_to :account, optional: true
    belongs_to :event, optional: true
    has_one :image_type, dependent: :destroy

    def as_json(options={})
        res = super
        res[:type] = image_type.image_type
        res[:type_decs] = image_type.description
        return res
    end
end
