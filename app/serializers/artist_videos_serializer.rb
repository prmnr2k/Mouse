class ArtistVideosSerializer < ActiveModel::Serializer
  attributes :id, :name, :link, :album_name
end