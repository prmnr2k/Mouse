class GenresController < ApplicationController
  swagger_controller :genres, "Genres"

  # GET /genres/all
  swagger_api :all do
    summary "Get genres list"
  end
  def all
    render json: GenresHelper.all, status: :ok
  end
end
