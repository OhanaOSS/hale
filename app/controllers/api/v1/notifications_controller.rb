class API::V1::NotificationsController < ApplicationController
  before_action :authenticate_api_v1_member!
  def unviewed
    begin
      @notifications = policy_scope(Notification).where(member_id: current_user.id).where.not(viewed: true)
      unless @notifications.empty?
        render json: @notifications, each_serializer: NotificationSerializer, adapter: :json_api
        @notifications.update_all(viewed: true)
      else
        render json: {data: []}, :status => :ok
      end
    rescue Pundit::NotAuthorizedError
      @notifications.errors.add(:id, :forbidden, message: "current user is not authorized to view notifications for that member_id.")
      render :json => { errors: @notifications.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  
  def all
    begin
      @notifications = policy_scope(Notification).where(member_id: current_user.id)
      unless @notifications.empty?
        render json: @notifications, each_serializer: NotificationSerializer, adapter: :json_api
        @notifications.where(viewed: false).update_all(viewed: true) if @notifications.exists?(viewed: false)
      else
        render json: {data: []}, :status => :ok
      end
    rescue Pundit::NotAuthorizedError
      @notifications.errors.add(:id, :forbidden, message: "current user is not authorized to view notifications for that member_id.")
      render :json => { errors: @notifications.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

end
