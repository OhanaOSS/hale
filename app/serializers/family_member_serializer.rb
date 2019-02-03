class FamilyMemberSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type "family-member"
  attributes :id, :family_id, :member_id, :authorized_at, :user_role, :updated_at, :created_at

  link(:self) { api_v1_family_member_path(object.id) }

  has_one :member, serializer: MemberPreviewSerializer do
    link(:related) { api_v1_member_path(object.member.id) }
  end
  has_one :family, serializer: FamilySerializer do
    link(:related) { api_v1_family_path(object.family.id) }
  end
end
