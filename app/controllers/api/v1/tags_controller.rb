class API::V1::TagsController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index
    @tags = Tag.all
    authorize @tags
    render json: @tags, each_serializer: TagSerializer, adapter: :json_api
  end
  def create
    begin
      @tag = Tag.new(tag_params)
      authorize @tag
      if @tag.save
        render json: @tag
      else
        render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @tag.errors.add(:id, :forbidden, message: "current user is not authorized to create tags")
      render :json => { errors: @tag.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  def destroy
    begin
      @tag = Tag.find(params[:id])
      authorize @tag
      @tag.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @tag.errors.add(:id, :forbidden, message: "current user is not authorized to destroy this tag")
      render :json => { errors: @tag.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end
  private
      def tag_params
      params.require(:tag).permit(:title, :description, :mature)
    end
end
