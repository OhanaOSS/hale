class InviteSerializer < ActiveModel::Serializer
  attributes :id, :email, :family_id, :sender_id, :recipient_id, :sent_at

  has_one :sender, serializer: MemberPreviewSerializer
  has_one :recipient, serializer: MemberPreviewSerializer
  has_one :family, serializer: FamilySerializer
end
