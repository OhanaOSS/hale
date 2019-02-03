class CommentReplySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  type "comment_reply"
  attributes :id, :body, :edit, :comment_id, :member_id, :created_at, :updated_at
    attribute :links do
    id = object.id
    comment_id = object.comment.id
    member_id = object.member.id
    {
      self: api_v1_comment_comment_reply_path(comment_id, id),
      comment: api_v1_comment_path(comment_id),
      member: api_v1_member_path(member_id)
    }
  end
  belongs_to :comment, serializer: CommentSerializer
  has_one :member, serializer: MemberPreviewSerializer
  has_many :reactions, serializer: ReactionPreviewSerializer
end
