class FeedController < ApplicationController
  before_action :authorize_account
  swagger_controller :feed, "Feed"

  # GET account/1/feeds
  swagger_api :index do
    summary "Account's feed"
    param :path, :account_id, :integer, :required, "Account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
  end
  def index
    following = @account.following.pluck('id')
    likes = Like.where(account_id: following).joins(:event).as_json(feed: true)
    likes.each do |e|
      e[:type] = 'like'
      e[:action] = ''
    end

    event_updates = EventUpdate.joins(:event).where(:events => {creator_id: following}).as_json(feed: true)
    event_updates.each do |e|
      e[:type] = "event update"
      e[:action] = "#{e['action']} #{e['field']}"
      e.delete('field')
    end
    #
    @feed = likes.concat(event_updates).sort_by{|u| u[:created_at]}

    render json: @feed
  end

  private
  def authorize_account
    @user = AuthorizeHelper.authorize(request)
    @account = Account.find(params[:account_id])
    render status: :unauthorized if @user == nil or @account.user != @user
  end

  def authorize
    @user = AuthorizeHelper.authorize(request)
    return @user != nil
  end
end