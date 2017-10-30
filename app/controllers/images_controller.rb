class ImagesController < ApplicationController
  # GET /images/1
  def show
    @image = Image.find(params[:id])
    render json: @image
  end

  #DELETE /images/<id>
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
