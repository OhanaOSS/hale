class API::V1::EventsController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index
    begin
      if params[:filter].present? && params[:filter][:scope] == "all"
        @events = policy_scope(Event).all
        render json: @events, each_serializer: EventSerializer, adapter: :json_api
      else
        begin
          @events = policy_scope(Event).where("event_start >= ?", Date.today)
          render json: @events
        rescue Pundit::NotDefinedError
          render json: {}, status: :no_content
        end
      end
    rescue Pundit::NotAuthorizedError
      @events.errors.add(:id, :forbidden, message: "current user is not authorized to view events")
      render :json => { errors: @events.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def show
    begin
      @event = Event.find(params[:id])
      authorize @event
      if @event.event_rsvps.any?
        render json: @event, serializer: EventSerializer, include: [:'event_rsvps'], adapter: :json_api, status: :ok
      else
        render json: @event, serializer: EventSerializer, adapter: :json_api
      end
    rescue Pundit::NotAuthorizedError
      @event.errors.add(:id, :forbidden, message: "current user is not authorized to view this event")
      render :json => { errors: @event.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def create
    begin
      @event = EventFactory.new(event_params).result
      authorize @event
      if @event.save
        @event.media.attach(event_params[:attributes][:media]) if event_params[:attributes][:media].present?
        # Callback to create EventRsvp of Event Creator.
        @event_rsvp = EventFactory.new(@event).event_creator_rsvp.save
        render json: @event, serializer: EventSerializer, include: [:'event_rsvps'], adapter: :json_api, status: :ok
      else
        render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @event.errors.add(:id, :forbidden, message: "current user is not authorized to create this event")
      render :json => { errors: @event.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def update
    begin
      @event = Event.find(params[:id])
      authorize @event
      @event.assign_attributes(update_event_params["attributes"])
      if @event.save
        render json: @event
      else
        render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @event.errors.add(:id, :forbidden, message: "current user is not authorized to update this event")
      render :json => { errors: @event.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

   def destroy
    begin
      @event = Event.find(params[:id])
      authorize @event
      @event.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @event.errors.add(:id, :forbidden, message: "current user is not authorized to delete this event")
      render :json => { errors: @event.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
   end

  private
    def update_event_params
      params.require(:event).permit(:id, :attributes => [:title, :description, :event_start, :event_end, :event_allday, :media, :locked, :potluck, :location => []])
    end
    def event_params
      params.require(:event).permit(:id, :attributes => [:title, :description, :event_start, :event_end, :event_allday, :media, :locked, :potluck, :family_id, :member_id, :location => []])
    end

end
