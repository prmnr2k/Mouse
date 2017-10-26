class ImagesController < ApplicationController
  # GET /images/1
  def show
    @image = Image.find(params[:id])
    render json: @image
  end
end
