class PhoneValidation < ApplicationRecord
    validates :phone, presence: true
end
