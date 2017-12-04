class ImagesController < ApplicationController
  swagger_controller :images, "Images"

  # GET /images/1
  swagger_api :show do
    summary "Get image object"
    param :path, :id, :integer, :required, "Image id"
    response :not_found
  end
  def show
    @image = Image.find(params[:id])
    render json: @image
  end

  #DELETE /images/<id>
  swagger_api :delete_image do
    summary "Delete image"
    param :path, :id, :integer, :required, "Image id"
    response :not_found
    response :forbidden
  end
  def delete_image
      @image = Image.find(params[:id])
        if @image.account.user == @user
            @image.account.image = nil if @image.account.image == @image
            @image.destroy
            @account.save
            render json: @account, status: :ok
        else
            render status: :forbidden
        end
  end

  def authorize_user
        @user = AuthorizeHelper.authorize(request)
        render status: :unauthorized if @user == nil
  end
end
