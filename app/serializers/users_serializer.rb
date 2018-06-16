class UsersSerializer < ActiveModel::Serializer
  attributes :id, :email, :google_id, :twitter_id, :register_phone, :vk_id
end
