class API::V1::CommentsController < ApplicationController
  before_action :authenticate_api_v1_member!
  before_action :load_comments, only: [:index]
  def index
    begin
      if request.path.include?("recipe")
        @comments = policy_scope(Comment).where(commentable_id: @commentable.id, commentable_type: @commentable.class.to_s)
        render json: @comments, each_serializer: CommentSerializer, adapter: :json_api
      else
        @comments = @commentable.comments
        render json: @comments, each_serializer: CommentSerializer, adapter: :json_api
      end
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comments.errors.add(:id, :forbidden, message: "current user is not authorized to view these comments")
      render :json => { errors: @comments.errors.full_messages }, :status => :forbidden
    end
  end

  def show
    begin
      @comment = Comment.find(params[:id])
      authorize @comment
      render json: @comment, serializer: CommentSerializer, adapter: :json_api
    rescue Pundit::NotAuthorizedError
      @comment.errors.add(:id, :forbidden, message: "current user is not authorized to view this comment")
      render :json => { errors: @comment.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def create
    begin
      @comment = Comment.new(comment_params)
      authorize @comment
      if @comment.save
        render json: @comment, serializer: CommentSerializer, adapter: :json_api
      else
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @comment.errors.add(:id, :forbidden, message: "current user is not authorized to create this comment")
      render :json => { errors: @comment.errors.full_messages }, :status => :forbidden
    end
  end

  def update
    begin
      @comment = Comment.find(params[:id])
      authorize @comment
      @comment.assign_attributes(comment_params["attributes"])
      if @comment.save
        render json: @comment, serializer: CommentSerializer, adapter: :json_api
      else
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @comment.errors.add(:id, :forbidden, message: "current user is not authorized to update this comment")
      render :json => { errors: @comment.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

   def destroy
    begin
      @comment = Comment.find(params[:comment][:id])
      authorize @comment
      @comment.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @comment.errors.add(:id, :forbidden, message: "current user is not authorized to update this comment")
      render :json => { errors: @comment.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
   end

  private
    def load_comments
      begin
        klass = [Post, Comment, Recipe].detect { |i| params["#{i.name.underscore}_id"]}
        @commentable = policy_scope(klass).find(params["#{klass.name.underscore}_id"])
      # rescue ActiveRecord::RecordNotFound
        # This will rescue if someone is trying to access 
        # the comments of a forbidden klass or normal 404.
        # render :json => {}, :status => :not_found
      end
    end
    def comment_params
      params.require(:comment).permit(:attributes =>[:body, :member_id, :commentable_id, :commentable_type, :media])
    end
end
