class EventSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type 'event'

  attributes :id, :title, :description, :media, :event_start, :event_end, :event_allday, :location, :potluck, :locked, :family_id, :member_id, :created_at, :updated_at

  def media # Required to avoid n+1 serialization failures.
    object.media.attached? ? rails_blob_path(object.media) : nil
  end

  link(:self) { api_v1_event_path(id: object.id) }

  has_one :member, serializer: MemberPreviewSerializer do
    link(:related) { api_v1_member_path(object.member_id) }
  end
  has_one :family, serializer: FamilySerializer do
    link(:related) { api_v1_families_path(object.family_id) }
  end
  has_many :comments, polymorphic: true, serializer: CommentSerializer do
    link(:related) { api_v1_event_comments_path(event_id: object.id) }
  end
  has_many :reactions, polymorphic: true, serializer: ReactionSerializer do
    link(:related) { api_v1_event_reactions_path(event_id: object.id) }
  end
  has_many :event_rsvps, serializer: EventRsvpSerializer do
    link(:related) { api_v1_events_rsvps_path(event_id: object.id) }
  end
end
