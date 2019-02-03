class API::V1::FamilyConfigsController < ApplicationController
  before_action :authenticate_api_v1_member!

  def show
    begin
      @family_config = FamilyConfig.find(params[:id])
      authorize @family_config
      render json: @family_config, serializer: FamilyConfigSerializer, adapter: :json_api
    rescue Pundit::NotAuthorizedError
      @family_config.errors.add(:id, :forbidden, message: "current user family_member.user_role is not authorized for family_config")
      render :json => { errors: @family_config.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  
  def update
    begin
      @family_config = FamilyConfig.find(params[:id])
      authorize @family_config
      @family_config.assign_attributes(config_params)
      if @family_config.save
        render json: @family_config, serializer: FamilyConfigSerializer, adapter: :json_api
      else
        render json: { errors: @family_config.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @family_config.errors.add(:id, :forbidden, message: "current user family_member.user_role is not authorized for family_config")
      render :json => { errors: @family_config.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  private
  def config_params
    params.require(:family_config).permit(:authorization_enabled)
  end
end
