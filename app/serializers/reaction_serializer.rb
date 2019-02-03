class ReactionSerializer < ActiveModel::Serializer
  type "reaction"
  attributes :id, :member_id, :emotive, :interaction_type, :interaction_id, :created_at
  has_one :interaction
  has_one :member, serializer: MemberPreviewSerializer do
     link(:member) { api_v1_member_path(id: object.member_id) }
  end
end
