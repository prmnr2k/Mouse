class EventVenuesController < ApplicationController
  before_action :set_event, only: [:create, :owner_accept, :owner_decline, :venue_accept, :venue_decline,
                                   :send_request, :venue_remove_active, :venue_set_active]
  before_action :set_message, only: [:owner_accept, :owner_decline, :venue_accept, :venue_decline]
  before_action :authorize_creator, only: [:create, :owner_accept, :owner_decline,
                                           :send_request, :venue_remove_active, :venue_set_active]
  before_action :authorize_venue, only: [:venue_accept, :venue_decline]
  swagger_controller :event_venues, "Event venues"

  # POST /events/1/venue
  swagger_api :create do
    summary "Add venue to event"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :venue_id, :integer, :required, "Venue account id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def create
    if venue_available?
      @event.venues << @venue_acc
      @event.save

      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end


  # POST /events/1/venue/1/send_request
  swagger_api :send_request do
    summary "Send request to the venue"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Venue account id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param_list :form, :time_frame, :integer, :required, "Time frame to answer", ["one_hour", "one_day", "one_week", "one_month"]
    param :form, :is_personal, :boolean, :optional, "Is message personal"
    param :form, :estimated_price, :integer, :optional, "Estimated price to perform"
    param :form, :message, :string, :optional, "Additional text"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def send_request
    @venue_event = @event.venue_events.find_by(venue_id: params[:id])

    if @venue_event and ["ready"].include?(@venue_event.status)
      venue_acc = Account.find(params[:id])

      if venue_acc
        @venue_event.status = 'request_send'
        send_mouse_request(venue_acc)
        @venue_event.save

        render status: :ok
      else
        render status: :not_found
      end
    else
      render status: :unprocessable_entity
    end
  end

  # POST /events/1/venue/1/owner_accept
  swagger_api :owner_accept do
    summary "Accept venue for event"
    param :path, :event_id, :integer, :required, "Event id"
    param :path, :id, :integer, :required, "Venue account id"
    param :form, :datetime_from, :datetime, :required, "Date and time of performance"
    param :form, :datetime_to, :datetime, :required, "Date and time of performance"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param :form, :message_id, :integer, :required, "Inbox message id"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def owner_accept
      @venue_event = @event.venue_events.find_by(venue_id: params[:id])

      if @event.venue_events.where(status: 'owner_accepted').count >= Rails.configuration.number_of_venues
        render status: :unprocessable_entity and return
      end

      if @message.is_read
        render status: :unprocessable_entity and return
      end

      if @venue_event and ["accepted"].include?(@venue_event.status)
        if date_valid?
          read_message
          @venue_event.status = 'owner_accepted'

          set_agreement
          change_event_date
          change_event_funding
          change_event_address
          send_accept_message(@venue_event.account)
          @venue_event.save

          render status: :ok
        else
          render status: :unprocessable_entity
        end
      else
        render status: :not_found
      end
  end

  # POST /events/1/venue/1/owner_decline
  swagger_api :owner_decline do
    summary "Decline venue for event"
    param :path, :id, :integer, :required, "Venue account id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Authorized account id"
    param_list :form, :reason, :string, :required, "Reason", ["price", "location", "time", "other"]
    param :form, :message_id, :integer, :optional, "Inbox message id"
    param :form, :additional_text, :string, :optional, "Message"
    param :header, 'Authorization', :string, :required, 'Authentication token'
    response :unauthorized
    response :unprocessable_entity
    response :not_found
  end
  def owner_decline
    @venue_event = @event.venue_events.find_by(venue_id: params[:id])

    if @message.is_read
      render status: :unprocessable_entity and return
    end

    if @venue_event and @venue_event.status != 'owner_accepted'
      read_message

      if @venue_event.status == 'owner_accepted'
        undo_change_event_date
        undo_change_event_funding
        undo_change_event_address
      end

      @venue_event.status = 'owner_declined'
      send_owner_decline(@venue_event.account)
      @venue_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/venue/1/venue_accept
  swagger_api :venue_accept do
    summary "Venue accepts request"
    param :path, :id, :integer, :required, "Venue id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :preferred_date_from, :datetime, :required, "Preferred date from"
    param :form, :preferred_date_to, :datetime, :required, "Preferred date to"
    param :form, :price, :integer, :required, "Price"
    param :form, :other_price, :integer, :optional, "Other price"
    param :form, :message_id, :integer, :required, "Inbox message id"
    param :header, 'Authorization', :string, :required, "Venue auth key"
  end
  def venue_accept
    @venue_event = @event.venue_events.find_by(venue_id: @account.id)

    if @message.is_read
      render status: :unprocessable_entity and return
    end

    if @venue_event and ["request_send"].include?(@venue_event.status)
      read_message
      @venue_event.status = 'accepted'
      send_approval(@account)
      @venue_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/venue/1/venue_decline
  swagger_api :venue_decline do
    summary "Venue declines request"
    param :path, :id, :integer, :required, "Venue id"
    param :path, :event_id, :integer, :required, "Event id"
    param_list :form, :reason, :string, :required, "Reason", ["price", "location", "time", "other"]
    param :form, :additional_text, :string, :optional, "Message"
    param :form, :message_id, :integer, :required, "Inbox message id"
    param :header, 'Authorization', :string, :required, "Venue auth key"
  end
  def venue_decline
    @venue_event = @event.venue_events.find_by(venue_id: @account.id)

    if @message.is_read
      render status: :unprocessable_entity and return
    end

    if @venue_event and ["request_send"].include?(@venue_event.status)
      read_message
      @venue_event.status = 'declined'
      send_decline(@account)
      @venue_event.save

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/venue/1/set_active
  swagger_api :venue_set_active do
    summary "Set venue active"
    param :path, :id, :integer, :required, "Venue id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Event owner id"
    param :header, 'Authorization', :string, :required, "Event owner auth key"
    response :not_found
    response :unprocessable_entity
    response :unauthorized
  end
  def venue_set_active
    @venue_acc = Account.find(params[:id])
    @venue_event = @event.venue_events.find_by(venue_id: @venue_acc.id)

    if @venue_event and @venue_event.status == "owner_accepted"
      @venue_event.status = "active"
      @venue_event.save!

      render status: :ok
    else
      render status: :not_found
    end
  end

  # POST /events/1/artist/1/remove_active
  swagger_api :venue_remove_active do
    summary "Remove active venue"
    param :path, :id, :integer, :required, "Venue id"
    param :path, :event_id, :integer, :required, "Event id"
    param :form, :account_id, :integer, :required, "Event owner id"
    param :header, 'Authorization', :string, :required, "Event owner auth key"
    response :not_found
    response :unauthorized
  end
  def venue_remove_active
    @venue_acc = Account.find(params[:id])
    @venue_event = @event.venue_events.find_by(venue_id: @venue_acc.id)

    if @venue_event and @venue_event.status == "active"
      @venue_event.status = "owner_accepted"
      @venue_event.save!

      render status: :ok
    else
      render status: :not_found
    end
  end

  private
  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_message
    @message = InboxMessage.find(params[:message_id])
  end

  def authorize_creator
    @user = AuthorizeHelper.authorize(request)
    @account = Account.find(params[:account_id])
    render status: :unauthorized and return if @user == nil or @account.user != @user

    @creator = Event.find(params[:event_id]).creator
    render status: :unauthorized if @creator != @account or @creator.user != @user
  end

  def authorize_venue
    @user = AuthorizeHelper.authorize(request)
    @account = Account.find(params[:id])
    render status: :unauthorized and return if @user == nil or @account.user != @user or @account.account_type != 'venue'
  end

  def send_mouse_request(account)
    request_message = RequestMessage.new(request_message_params)
    request_message.save

    inbox_message = InboxMessage.new(name: "#{@event.name} request", message_type: "request")
    inbox_message.request_message = request_message

    @event.request_messages << request_message
    @event.creator.sent_messages << inbox_message
    account.inbox_messages << inbox_message
    inbox_message.save
  end

  def send_approval(account)
    accept_message = AcceptMessage.new(accept_message_params)
    accept_message.save

    inbox_message = InboxMessage.new(name: "#{account.user_name} accepted #{@event.name} invitation", message_type: "accept")
    inbox_message.accept_message = accept_message

    @event.accept_messages << accept_message
    @event.creator.inbox_messages << inbox_message
    account.sent_messages << inbox_message
  end

  def send_decline(account)
    decline_message = DeclineMessage.new(decline_message_params)
    decline_message.save

    inbox_message = InboxMessage.new(name: "#{account.user_name} declined #{@event.name} invitation", message_type: "decline")
    inbox_message.decline_message = decline_message

    @event.decline_messages << decline_message
    @event.creator.inbox_messages << inbox_message
    account.sent_messages << inbox_message
  end

  def send_owner_decline(account)
    decline_message = DeclineMessage.new(decline_message_params)
    decline_message.save

    inbox_message = InboxMessage.new(name: "#{@event.name} owner reply", message_type: "decline")
    inbox_message.decline_message = decline_message

    @event.decline_messages << decline_message
    account.inbox_messages << inbox_message
    @event.creator.sent_messages << inbox_message
  end

  def send_accept_message(account)
    inbox_message = InboxMessage.new(
      name: "#{@event.name} owner reply",
      message_type: "blank",
      simple_message: "#{@event.name} owner accepted your conteroffer"
    )

    @event.creator.sent_messages << inbox_message
    account.inbox_messages << inbox_message
  end

  def set_agreement
    agreement = AgreedDateTimeAndPrice.new(agreement_params)
    agreement.price = @message.accept_message.price
    agreement.venue_event = @venue_event
    agreement.save!
  end

  def read_message
    @message.is_read = true
    @message.save
  end

  def request_message_params
    params.permit(:time_frame, :is_personal, :estimated_price, :message)
  end

  def accept_message_params
    params.permit(:preferred_date_from, :preferred_date_to, :price,
                  :travel_price, :hotel_price, :transportation_price, :band_price, :other_price)
  end

  def decline_message_params
    params.permit(:reason, :additional_text)
  end

  def agreement_params
    params.permit(:datetime_from, :datetime_to, :price)
  end

  def venue_available?
    @venue_acc = Account.find(params[:venue_id])

    if @venue_acc and @venue_acc.account_type == 'venue'
      #and @event.venue_events.where.not(status: 'declined').count < Rails.configuration.number_of_venues
      return true
    end

    return false
  end

  def date_valid?
    #unless @venue_event.agreed_date_time_and_price
    #  return false
    #end

    if @event.date_from.nil?
      return true
    end

    agreed_date = @venue_event.agreed_date_time_and_price
    if @event.date_from <= agreed_date.datetime_from and @event.date_to >= agreed_date.datetime_to
      return true
    end
    return false
  end

  def change_event_date
    @event.old_date_from = @event.date_from
    @event.old_date_to = @event.date_to
    @event.date_from = @venue_event.agreed_date_time_and_price.datetime_from
    @event.date_to = @venue_event.agreed_date_time_and_price.datetime_to
    @event.save!
  end

  def undo_change_event_date
    @event.date_from = @event.old_date_from
    @event.date_to = @event.old_date_to
    @event.old_date_from = nil
    @event.old_date_to = nil
    @event.save!
  end

  def change_event_funding
    @event.funding_goal += @venue_event.agreed_date_time_and_price.price
    @event.save!
  end

  def undo_change_event_funding
    @event.funding_goal -= @venue_event.agreed_date_time_and_price.price
    @event.save!
  end

  def change_event_address
    @venue_acc = @venue_event.account

    # save to rollback
    @event.old_address = @event.address
    @event.old_city_lat = @event.city_lat
    @event.old_city_lng = @event.city_lng

    @event.address = @venue_acc.venue.address
    @event.city_lat = @venue_acc.venue.lat
    @event.city_lng = @venue_acc.venue.lng
    @event.venue_id = @venue_acc.id
    @event.save!
  end

  def undo_change_event_address
    @event.address = @event.old_address
    @event.city_lat = @event.old_city_lat
    @event.city_lng = @event.old_city_lng
    @event.venue_id = nil

    @event.save!
  end
end