class MemberPreviewSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  type "member"
  attributes :id, :name, :surname, :nickname, :avatar

  def avatar # Required to avoid n+1 serialization failures.
    object.avatar.attached? ? rails_blob_path(object.avatar) : "assets/images/default_avatar.png"
  end

  attribute :links do
    member_id = object.id
    {
      self: api_v1_member_path(member_id)
    }
  end
end
