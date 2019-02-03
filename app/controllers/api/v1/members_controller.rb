class API::V1::MembersController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index # alias Directory
    @members = policy_scope(Member) || []
    render json: @members, each_serializer: DirectoryMemberSerializer, adapter: :json_api
  end
  def show
    begin
      @member = Member.find(params[:id])
      authorize @member
      render json: ActiveModelSerializers::SerializableResource.new(@member, each_serializer: ProfileSerializer, scope: current_user, scope_name: :current_user, adapter: :json_api)
    rescue Pundit::NotAuthorizedError
      @member.errors.add(:id, :forbidden, message: "current user is not authorized to view member id: #{params[:id]}")
      render :json => { errors: @member.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  def update
    begin
      @member = Member.find(params[:id])
      authorize @member
      @member.assign_attributes(member_params)
      if @member.save
        render json: ActiveModelSerializers::SerializableResource.new(@member, each_serializer: ProfileSerializer, scope: current_user, scope_name: :current_user, adapter: :json_api)
      else
        render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @member.errors.add(:id, :forbidden, message: "current user is not authorized to update member id: #{params[:id]}")
      render :json => { errors: @member.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def create
    begin
      @member = Member.new(create_member_params)
      authorize @member
      if @member.save
        FamilyMember.create(member_id: @member.id, family_id: params[:family][:family_id])
        render json: ActiveModelSerializers::SerializableResource.new(@member, each_serializer: ProfileSerializer, scope: current_user, scope_name: :current_user, adapter: :json_api)
      else
        render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      @member = Member.new if @member == nil
      @member.errors.add(:id, :bad_request, message: "Please register via POST '/v1/auth/'.") unless current_user != nil || current_user.family_members.where('user_role >= ?', 2).exists?
      @member.errors.add(:id, :bad_request, message: "Family_name or family_id is missing from the request.") if !params.keys.include?("family")
      render json: { errors: @member.errors.full_messages }, status: :bad_request
    end
  end

  def destroy
    begin
      @member = Member.find(member_params[:id])
      authorize @member
      if @member.destroy
        render json: {}, status: :no_content
      else
        render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @member.errors.add(:id, :forbidden, message: "current user is not authorized to delete member id: #{params[:id]}")
      render :json => { errors: @member.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  private
  def create_member_params
    params.require(:family).permit(:family_id)
    params.require(:member).permit(:user_role, :email, :password, :name, :surname)
  end
  def member_params
    params.require(:member).permit(:id, :attributes =>[:avatar, :name, :surname, :nickname, :gender, :bio, :birthday, :instagram, :email, :addresses => [:type, "line-1", "line-2", :city, :state, :postal], :contacts => [:home, :work, :cell] ])
  end
end
