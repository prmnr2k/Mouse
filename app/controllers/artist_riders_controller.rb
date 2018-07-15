class ArtistRidersController < ApplicationController
  swagger_controller :artist_riders, "Artist Riders"

  # GET /artist_riders/1
  swagger_api :show do
    summary "Get full artist riders object"
    param :path, :id, :integer, :required, "Artist rider id"
    response :not_found
  end
  def show
    @rider = ArtistRider.find(params[:id])
    render json: @rider, file_info: true
  end

  param :form, :artist_riders, :string, :optional, "Artist array of riders objects
                                [{'rider_type': 'stage|backstage|hospitality|technical', 'uploaded_file_base64': '', 'description': '', 'is_flexible': ''}, {...}]"
  def create

  end

  private
  def set_artist_riders
    if params[:artist_riders]
      @artist.artist_riders.clear
      params[:artist_riders].each do |rider|
        obj = ArtistRider.new(artist_rider_params(rider))
        obj.save
        @artist.artist_riders << obj
      end
      @artist.save
    end
  end


  def artist_rider_params(rider)
    rider.permit(:rider_type, :description, :is_flexible, :uploaded_file_base64)
  end

end
