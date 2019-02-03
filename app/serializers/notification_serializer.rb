class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :notifiable_type, :notifiable_id, :member_id, :mentioned, :viewed, :created_at, :updated_at

  has_one :notifiable 
  # do
  #   notifiable_type = object.notifiable_type
  #   
  #   link(:notifiable) { api_v1_post_path(id: object.notifiable_id) } if notifiable_type == "Post"
  #   link(:notifiable) { api_v1_events_path(id: object.notifiable_id) } if notifiable_type == "Event"
  #   link(:notifiable) { api_v1_recipes_path(id: object.notifiable_id) } if notifiable_type == "Recipe"
  #   link(:notifiable) { api_v1_comment_path(id: object.notifiable_id) } if notifiable_type == "Comment"
  #   link(:notifiable) { api_v1_comment_comment_path(object.notifiable.commentable_id, object.notifiable_id) } if notifiable_type == "CommentReply"
  #   link(:notifiable) { api_v1_reaction_path(id: object.notifiable_id) } if notifiable_type == "Reaction"
  # end
  has_one :member, serializer: MemberPreviewSerializer do
    link(:self) { api_v1_member_path(id: object.member_id) }
  end
end
