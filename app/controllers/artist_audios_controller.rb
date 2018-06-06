class ArtistAudiosController

  swagger_api :create do
    param :form, :audio_links, :string, :optional, "Array of links to audio of artist [{'song_name': '', 'album_name': '', 'audio_link': ''}, {...}]"
  end
  def create

  end

  private

  def set_artist_audios
    if params[:audio_links]
      objs = []
      params[:audio_links].each do |link|
        if link["audio_link"].start_with?("https://open.spotify.com/")
          obj = AudioLink.new(artist_audio_params(link))
          obj.save
          objs << obj
        else
          objs.clear
          return false
        end
      end

      @artist.audio_links.clear
      @artist.audio_links << objs
      @artist.save
    end
  end

  def artist_audio_params(link)
    link.permit(:audio_link, :song_name, :album_name)
  end
end