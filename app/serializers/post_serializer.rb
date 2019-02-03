class PostSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type 'post'
  attributes :id, :family_id, :member_id, :body, :location, :media, :edit, :locked, :created_at, :updated_at

  def media # Required to avoid n+1 serialization failures.
    object.media.attached? ? rails_blob_path(object.media) : nil
  end

  link(:self) { api_v1_post_path(id: object.id) }
  link(:comments) { api_v1_post_comments_path(object.id) }
  link(:member) { api_v1_member_path(id: object.member.id) }

  has_one :member, serializer: MemberPreviewSerializer do
    link(:related) { api_v1_member_path(id: object.member.id) }
  end
  has_many :comments, polymorphic: true, serializer: CommentSerializer do
    link(:related) { api_v1_post_comments_path(object.id) }
  end
  has_many :reactions, polymorphic: true, serializer: ReactionPreviewSerializer do
    link(:related) { api_v1_post_reactions_path(object.id) }
  end
end