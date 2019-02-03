class API::V1::FamiliesController < ApplicationController
  before_action :authenticate_api_v1_member!, except: [:index]
  def index
    # Used for signup selection and selecting show
    @families = Family.all
    render json: @families, each_serializer: FamilySerializer, adapter: :json_api
  end

  def show
    begin
      @family = Family.find(params[:id])
      authorize @family
      @family_members = Member.joins(:family_members).where(family_members: { family_id: @family.id })
      render json: @family_members, each_serializer: DirectoryMemberSerializer, adapter: :json_api
    rescue Pundit::NotAuthorizedError
      @family.errors.add(:id, :forbidden, message: "current user is not authorized to view these family members")
      render :json => { errors: @family.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  def update
    begin
      @family = Family.find(params[:id])
      authorize @family
      if @family.update(family_params)
        render json: @family
      else
        render json: { errors: @family.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @family.errors.add(:id, :forbidden, message: "current user is not authorized to update this family ")
      render :json => { errors: @family.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def destroy
    begin
      @family = Family.find(params[:id])
      authorize @family
      @family.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @family.errors.add(:id, :forbidden, message: "current user is not authorized to delete this family ")
      render :json => { errors: @family.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  # Mass Invites, if inviting one by one use Invite controller.
  # Purpose is mainly to initally onboard a family.
  def invite_to
    begin
      @family = Family.find(params[:id])
      authorize @family
      emails = family_params[:invite_emails].split(', ')

      emails.each do |email|
        invite = Invite.new(:sender_id => current_user.id, :email => email, :family_id => @family.id)
        if invite.save
          InviteMailer.new_user_invite(invite, new_api_v1_member_registration_url(:invite_token => invite.token))
        end
      end
      invites = Invite.where(:sender_id => current_user.id, :family_id => @family.id)
      render :json => {data: {"message": "Sent #{invites.count} invites to: #{invites.pluck(:email).join(", ")}"} }
    rescue Pundit::NotAuthorizedError
      @family.errors.add(:id, :forbidden, message: "current user is not authorized to delete this family ")
      render :json => { errors: @family.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  private

  def family_params
    # Whitelist of Params
    params.require(:family).permit(:id, :invite_emails, :attributes => [:family_name])
  end

end
