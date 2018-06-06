class ArtisVideosController

  swagger_api :create do
    param :form, :artist_videos, :string, :optional, "Array of link objects [{'name': '', 'album_name': '', 'link': ''}, {...}]"
  end
  def create

  end

  private
  def set_artist_video_links
    if params[:artist_videos]
      @artist.artist_videos.clear
      params[:artist_videos].each do |link|
        obj = ArtistVideo.new(artist_video_params(link))
        obj.save
        @artist.artist_videos << obj
      end
      @artist.save
    end
  end

  def artist_video_params(video)
    video.permit(:link, :name, :album_name)
  end

end