class ArtistVideosController < ApplicationController
  before_action :authorize_artist
  swagger_controller :artist_video, "Artist's video"

  swagger_api :index do
    summary "Retrieve artist's video"
    param :path, :artist_id, :integer, :required, "Artist id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end

  def index
    render json: @artist.artist_videos, each_serializer: ArtistVideosSerializer, status: :created
  end

  swagger_api :create do
    summary "Add artist's video"
    param :path, :artist_id, :integer, :required, "Artist id"
    param :form, :name, :string, :required, "Video name"
    param :form, :album_name, :string, :optional, "Video album name"
    param :form, :link, :string, :required, "Link"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end

  def create
    artist_video = ArtistVideo.new(artist_video_params)
    artist_video.artist = @artist

    if artist_video.save
      @artist.artist_videos << artist_video
      @artist.save

      render json: artist_video, serializer: ArtistVideosSerializer, status: :created
    else
      render json: artist_video.errors, status: :unprocessable_entity
    end
  end

  swagger_api :destroy do
    summary "Delete artist video"
    param :path, :id, :integer, :required, "Video id"
    param :path, :artist_id, :integer, :required, "Artist id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
  end

  def destroy
    artist_video = @artist.artist_videos.find(params[:id])
    if artist_video.destroy
      render status: :ok
    else
      render json: artist_video.errors, status: :unprocessable_entity
    end
  end

  private
  def authorize_artist
    @artist = AuthenticateHelper.authorize_and_get_account(request, params[:artist_id]).specific
    if @artist == nil
      render status: :unauthorized and return
    end
  end

  def artist_video_params
    params.permit(:link, :name, :album_name)
  end

end