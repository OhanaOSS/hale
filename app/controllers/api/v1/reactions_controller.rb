class API::V1::ReactionsController < ApplicationController
  before_action :authenticate_api_v1_member!
  before_action :load_interactions
  skip_before_action :load_interactions, only: [:create, :destroy]
  def index
    begin
      @reactions = policy_scope(Reaction).where(interaction_id: @interaction.id, interaction_type: @interaction.class.to_s)
      render json: @reactions, each_serializer: ReactionSerializer, adapter: :json_api
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @reactions.errors.add(:id, :forbidden, message: "current user is not authorized to view these reactions")
      render :json => { errors: @reactions.errors.full_messages }, :status => :forbidden
    end
  end
  
  def create
    begin
      @reaction = Reaction.new(reaction_params)
      authorize @reaction
      if @reaction.save
        render json: @reaction
      else
        render json: { errors: @reaction.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @reaction.errors.add(:id, :forbidden, message: "current user is not authorized to create this reaction")
      render :json => { errors: @reaction.errors.full_messages }, :status => :forbidden
    end
  end

  def destroy
    begin
      @reaction = Reaction.find(params[:id])
      authorize @reaction
      @reaction.destroy
      render json: {}, status: :no_content
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @reaction.errors.add(:id, :forbidden, message: "current user is not authorized to create this reaction")
      render :json => { errors: @reaction.errors.full_messages }, :status => :forbidden
    end
  end

  private
  
  def load_interactions
    klass = [Post, Comment, CommentReply, Recipe].detect { |i| params["#{i.name.underscore}_id"]}
    @interaction = klass.find(params["#{klass.name.underscore}_id"])
  end

  def reaction_params
    params.require(:reaction).permit(:id, :type, :attributes => [:member_id, :emotive, :interaction_type, :interaction_id])
  end

end
