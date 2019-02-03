class API::V1::InvitesController < ApplicationController
  before_action :authenticate_api_v1_member!

  def create
    begin
      @invite = Invite.new(invite_params)
      authorize @invite
      @invite.sender_id = current_user.id
      if @invite.save

        #if the user already exists
        if @invite.recipient != nil 
          InviteMailer.existing_user_invite(@invite).deliver
          render json: @invite, each_serializer: InviteSerializer, adapter: :json_api
        else
          InviteMailer.new_user_invite(@invite, new_api_v1_member_registration_url(:invite_token => @invite.token)).deliver
          render json: @invite, each_serializer: InviteSerializer, adapter: :json_api
        end
      else
        render json: { errors: @invite.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @invite.errors.add(:id, :forbidden, message: "current user is not authorized to create this invite")
      render :json => { errors: @invite.errors.full_messages }, :status => :forbidden
    end
  end
  private
  def invite_params
    params.require(:invite).permit(:family_id, :sender_id, :recipient_id, :email)
  end

end
