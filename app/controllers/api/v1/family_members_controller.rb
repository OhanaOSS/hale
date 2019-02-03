class API::V1::FamilyMembersController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index
    begin
      @family_members = FamilyMember.where(family_id: current_user.family_ids)
      authorize @family_members
      render json: @family_members
    rescue Pundit::NotAuthorizedError
      render json: {}, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  def update
    begin
      @family_member = FamilyMember.find(params[:id])
      @family_member.assign_attributes(family_member_params)
      authorize @family_member
      if @family_member.save
        render json: @family_member
      else
        render json: { errors: @family_member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @family_member.errors.add(:id, :forbidden, message: "current user is not authorized to update this family_member record")
      render :json => { errors: @family_member.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def destroy
    begin
      @family_member = FamilyMember.find(params[:id])
      authorize @family_member
      @family_member.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @family_member.errors.add(:id, :forbidden, message: "current user is not authorized to delete this family_member record")
      render :json => { errors: @family_member.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  private
  def family_member_params
    params.require(:family_member).permit(:id, :member_id, :user_role, :authorized_at)
  end
end
