class PostPreviewSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type 'post'
  attributes :id, :family_id, :member_id, :body, :location, :locked, :created_at, :updated_at
  link(:self) { api_v1_post_path(id: object.id) }
  link(:comments) { api_v1_post_comments_path(object.id) }
  link(:member) { api_v1_member_path(id: object.member.id) }

  has_many :comments, polymorphic: true, serializer: CommentSerializer do
    # object.each do
    link(:related) { api_v1_post_comments_path(object.id) }
  end

end
