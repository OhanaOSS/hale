class CommentPreviewSerializer < ActiveModel::Serializer
  type "comment"
  attributes :id, :body, :member_id, :media
  def media # Required to avoid n+1 serialization failures.
    object.media.attached? ? rails_blob_path(object.media) : nil
  end
end
