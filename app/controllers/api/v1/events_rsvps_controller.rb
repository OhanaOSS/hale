class API::V1::EventsRsvpsController < ApplicationController
  before_action :authenticate_api_v1_member!
  def create
    begin
      @event_rsvp = EventRsvp.new(event_rsvp_params)
      authorize @event_rsvp
      unless EventRsvp.exists?(event_id: event_rsvp_params["attributes"]["event_id"], member_id: event_rsvp_params["attributes"]["member_id"])
        if @event_rsvp.save
          render json: @event_rsvp
        else
          render json: { errors: @event_rsvp.errors.full_messages }, status: :unprocessable_entity
        end
      else
        conflicting_event_rsvp = EventRsvp.where(event_id: event_rsvp_params["attributes"]["event_id"], member_id: event_rsvp_params["attributes"]["member_id"]).first
        @event_rsvp.errors.add(:id, :conflict, message: "Conflicting RSVP, please send PUT/PATCH to update event_rsvp id: #{conflicting_event_rsvp.id}")
        render json: { errors: @event_rsvp.errors.full_messages }, status: :conflict
      end
    rescue Pundit::NotAuthorizedError
      @event_rsvp.errors.add(:id, :forbidden, message: "current user is not authorized to create this event_rsvp")
      render :json => { errors: @event_rsvp.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def update
    begin
      @event_rsvp = EventRsvp.find(params[:id])
      @event_rsvp.assign_attributes(update_event_rsvp_params)
      authorize @event_rsvp
      if @event_rsvp.save
        render json: @event_rsvp
      else
        render json: { errors: @event_rsvp.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @event_rsvp.errors.add(:id, :forbidden, message: "current user is not authorized to update this event_rsvp")
      render :json => { errors: @event_rsvp.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def destroy
    begin
      @event_rsvp = EventRsvp.find(params[:id])
      authorize @event_rsvp
      @event_rsvp.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @event_rsvp.errors.add(:id, :forbidden, message: "current user is not authorized to delete this event_rsvp")
      render :json => { errors: @event_rsvp.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  private
  def update_event_rsvp_params
    params.require(:event_rsvp).permit(:id, :attributes => [:party_size, :rsvp, :bringing_food, :recipe_id, :non_recipe_description, :serving, :event_id, :rsvp_note, :created_at, :updated_at, :party_companions => {}])
  end
  def event_rsvp_params
    params.require(:event_rsvp).permit(:id, :attributes => [:party_size, :rsvp, :bringing_food, :recipe_id, :non_recipe_description, :serving, :member_id, :event_id, :rsvp_note, :created_at, :updated_at, :party_companions => []])
  end

end
