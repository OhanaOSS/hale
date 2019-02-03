class API::V1::CommentReplysController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index
    begin
      @comment_replys = policy_scope(CommentReply).where(comment_id: params[:comment_id])
      render json: @comment_replys, each_serializer: CommentReplySerializer, adapter: :json_api
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comment_replys.errors.add(:id, :forbidden, message: "current user is not authorized to view these comment_replys")
      render :json => { errors: @comment_replys.errors.full_messages }, :status => :forbidden
    end
  end
  
  def show
    begin
      @comment_reply = CommentReply.find(params[:id])
      authorize @comment_reply
      render json: @comment_reply, serializer: CommentReplySerializer, adapter: :json_api
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comment_reply.errors.add(:id, :forbidden, message: "current user is not authorized to view these comment_replys")
      render :json => { errors: @comment_reply.errors.full_messages }, :status => :forbidden
    end
  end

  def create
    begin
      @comment_reply = CommentReply.new(comment_reply_params)
      authorize @comment_reply
      if @comment_reply.save
        render json: @comment_reply, serializer: CommentReplySerializer, adapter: :json_api
      else
        render json: { errors: @comment_reply.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comment_reply.errors.add(:id, :forbidden, message: "current user is not authorized to view these comment_replys")
      render :json => { errors: @comment_reply.errors.full_messages }, :status => :forbidden
    end
  end

  def update
    begin
      @comment_reply = CommentReply.find(params[:id])
      authorize @comment_reply
      @comment_reply.assign_attributes(comment_reply_params)

      if @comment_reply.save
        render json: @comment_reply, serializer: CommentReplySerializer, adapter: :json_api
      else
        render json: { errors: @comment_reply.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comment_reply.errors.add(:id, :forbidden, message: "current user is not authorized to view these comment_replys")
      render :json => { errors: @comment_reply.errors.full_messages }, :status => :forbidden
    end
  end

  def destroy
    begin
      @comment_reply = CommentReply.find(params[:id])
      authorize @comment_reply
      @comment_reply.destroy
      render json: {}, status: :no_content
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    rescue Pundit::NotAuthorizedError
      @comment_reply.errors.add(:id, :forbidden, message: "current user is not authorized to view these comment_replys")
      render :json => { errors: @comment_reply.errors.full_messages }, :status => :forbidden
    end
  end

  private
    def comment_reply_params
      params.require(:comment_reply).permit(:attributes => [:id, :body, :attachment, :member_id, :comment_id])
    end
end