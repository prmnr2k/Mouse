class ArtistAlbumsController

  swagger_api :create do

    param :form, :artist_albums, :string, :optional, "Array of artist albums objects [{'album_name': '', 'album_artwork': '', 'album_link': ''}, {...}]"
  end
  def create

  end

  private
  def set_artist_albums
    if params[:artist_albums]
      @artist.artist_albums.clear
      params[:artist_albums].each do |album|
        obj = ArtistAlbum.new(artist_album_params(album))
        obj.save
        @artist.artist_albums << obj
      end
      @artist.save
    end
  end

  def artist_album_params(album)
    album.permit(:album_name, :album_artwork, :album_link)
  end
end