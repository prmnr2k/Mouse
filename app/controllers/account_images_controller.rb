class AccountImagesController < ApplicationController
  before_action :authorize_account
  swagger_controller :account_images, "Account images"

  # GET /accounts/<account_id>/account_images
  swagger_api :index do
    summary "Retrieve list of images"
    param :path, :account_id, :integer, :required, "Account id"
    param :query, :limit, :integer, :optional, "Limit"
    param :query, :offset, :integer, :optional, "Offset"
    response :not_found
  end

  def index
    images = @account.images.where(
      "base64 is not null and base64 != ''"
    )
    if @account.image_id != nil
      images = images.where("id != :id", {id: @account.image_id})
    end

    render json: {
      total_count: images.count,
      images: images.limit(params[:limit]).offset(params[:offset])
    }, image_only: true, status: :ok
  end

  # POST /accounts/<account_id>/account_images
  swagger_api :create do
    param :path, :account_id, :integer, :required, "Account id"
    param :form, :image, :file, :required, "Image"
    param :form, :image_description, :string, :optional, "Image description"
    param_list :form, :image_type, :string, :optional, "Image type",
               ["night_club", "concert_hall", "event_space", "theatre", "additional_room", "stadium_arena", "outdoor_space", "other"]
    param :form, :image_type_description, :string, :optional, "Image other type description"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :created
  end

  def create
    create_image

    if performed?
      render json: @image, status: :created
    end
  end

  # POST /accounts/<account_id>/account_images/base64
  swagger_api :create_base64 do
    param :path, :account_id, :integer, :required, "Account id"
    param :form, :image_base64, :string, :required, "Image base64 string"
    param :form, :image_description, :string, :optional, "Image description"
    param_list :form, :image_type, :string, :optional, "Image type",
               ["night_club", "concert_hall", "event_space", "theatre", "additional_room", "stadium_arena", "outdoor_space", "other"]
    param :form, :image_type_description, :string, :optional, "Image other type description"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :created
  end

  def create_base64
    create_base64_image

    if performed?
      render json: @image, status: :created
    end
  end

  # POST /accounts/<account_id>/account_images/change
  swagger_api :change do
    summary "Upload image to Account"
    param :path, :id, :integer, :required, "Account id"
    param :form, :image, :file, :required, "Image to upload"
    param :form, :image_description, :string, :optional, "Image description"
    param_list :form, :image_type, :string, :optional, "Image type",
               ["night_club", "concert_hall", "event_space", "theatre", "additional_room", "stadium_arena", "outdoor_space", "other"]
    param :form, :image_type_description, :string, :optional, "Image other type description"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
    response :created
  end

  def change
    set_image

    if performed?
      render json: @account, status: :created
    end
  end

  # POST /accounts/<account_id>/account_images/change_base64
  swagger_api :change_base64 do
    summary "Upload image to Account"
    param :path, :id, :integer, :required, "Account id"
    param :form, :image_base64, :string, :required, "Image base64 string"
    param :form, :image_description, :string, :optional, "Image description"
    param_list :form, :image_type, :string, :optional, "Image type",
               ["night_club", "concert_hall", "event_space", "theatre", "additional_room", "stadium_arena", "outdoor_space", "other"]
    param :form, :image_type_description, :string, :optional, "Image other type description"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unprocessable_entity
    response :unauthorized
    response :not_found
  end

  def change_base64
    set_base64_image

    if performed?
      render json: @account, status: :created
    end
  end


  private
  def authorize_account
    AuthenticateHelper.authorize_and_get_account(request, "account_id")
  end

  def create_image
    @image = Image.new(description: params[:image_description], base64: Base64.encode64(File.read(params[:image].path)))
    if not @image.save
      render json: @image.errors, status: :unprocessable_entity
    else
      set_image_type

      if performed?
        @account.images << @image
      end
    end
  end

  def create_base64_image
    @image = Image.new(description: params[:image_description], base64: params[:image_base64])
    if not @image.save
      render json: @image.errors, status: :unprocessable_entity
    else
      set_image_type

      if performed?
        @account.images << @image
      end
    end
  end

  def set_image
    create_image

    if performed?
      @account.image = @image
    end
  end

  def set_base64_image
    create_base64_image

    if performed?
      @account.image = @image
    end
  end

  def set_image_type
    if params[:image_type]
      image_type = ImageType.new(image_type: ImageType.image_types[params[:image_type]])
      if params[:image_type_description]
        image_type.description = params[:image_type_description]
      end

      if image_type.save
        @image.image_type = image_type
      else
        @image.destroy
        render image_type.errors, status: :unprocessable_entity
      end
    end
  end
end