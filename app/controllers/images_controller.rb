class ImagesController < ApplicationController
  before_action :authorize_account, only: [:delete_image]
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
    param :form, :account_id, :integer, :required, "Account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :not_found
    response :forbidden
  end
  def delete_image
      @image = Image.find(params[:id])
      if @image.account.user == @user and @image.account == @account
        @account.image = nil if @account.image == @image
        @image.destroy
        @account.save
        render json: @account, status: :ok
      else
        render status: :forbidden
      end
  end

  private
    def authorize_account
      @user = AuthorizeHelper.authorize(request)
      @account = Account.find(params[:account_id])
      render status: :unauthorized if @user == nil or @account.user != @user
    end
end
