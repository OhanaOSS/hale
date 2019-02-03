class ReactionPreviewSerializer < ActiveModel::Serializer
  type "reaction"
  attributes :id, :member_id, :emotive
end
