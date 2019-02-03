class API::V1::RegistrationsController < DeviseTokenAuth::RegistrationsController
  def create
    super do |resource|
      begin
        if @invite_params.present? && @invite_params[:invite_token] != nil
          @token = @invite_params[:invite_token]
          invite = Invite.find_by_token(@token)
          invite.update_attributes(recipient_id: resource.id) # update the recipient_id
          create_new_family_member(invite.family_id) # create new family member based on @token.family
        elsif @family_params.present? && @family_params[:family_name].present?
          if @family_params[:config].present?
            create_new_family(family_name: @family_params[:family_name], config: @family_params[:config])
          else
            create_new_family(family_name: @family_params[:family_name]) 
          end
        elsif @family_params.present? && @family_params[:family_id].present? && !@invite_params.present?
          create_new_family_member(@family_params[:family_id])
        else
          # whoops something went wrong
        end
        @family_id = resource.family_members.first.family_id
      rescue

      ensure
        # if sucessful_registration?(@family_id, @resource)
          authorization_processor(@family_id, @resource)
          # # Void Invite token once sucessfully registered.
          # Invite.find_by_token(@token).update_attributes(accepted_at: DateTime.now, token: nil) if @token.present? && @family_id != nil
        # end
      end
    end
  end # create

private

  # def sucessful_registration?(@family_id, @resource)
  #   raise some_failed_registration_rescue unless FamilyMember.exists?(family_id: @family_id, member_id: @resource.id)
  # end

  def create_new_family_member(family_id)
    new_family_member = FamilyMember.find_or_create_by(family_id: family_id, member_id: @resource.id)
  end

  def create_new_family(family_name:, config: nil)
    new_family = Family.find_or_create_by(family_name: family_name)
    new_family_config = FamilyConfig.find_or_create_by(family_id: new_family.id)
    new_family_member = FamilyMember.find_or_create_by(family_id: new_family.id, member_id: @resource.id).update_attributes(user_role: "owner", authorized_at: DateTime.now)
    unless config.nil?
      FamilyConfig.find_by(family_id: new_family.id).update(config)
    end
  end
  
  def authorization_processor(family_id, resource)
      # if authorization_enabled is false, auto-authorize family_member
      if FamilyConfig.find_by(family_id: family_id).authorization_enabled == false
        record = FamilyMember.find_by(family_id: family_id, member_id: resource.id)
        record.update_attributes(authorized_at: DateTime.now)
      end
  end
  def sign_up_params
    @invite_params = params.permit(:invite_token)
    # Not required if @invite_params is registering a new user via an invitation.
    @family_params = params.require(:family).permit(:family_name, :family_id, :config => [:authorization_enabled]) unless @invite_params.present?
    params.require(:registration).permit(:email, :password, :password_confirmation, :name, :surname, :confirm_success_url, :confirm_error_url)
  end

end