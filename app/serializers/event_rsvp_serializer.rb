class EventRsvpSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  type "event_rsvp"

  attributes :id, :party_size, :rsvp, :bringing_food, :recipe_id, :non_recipe_description, :serving, :member_id, :party_companions, :event_id, :rsvp_note, :created_at, :updated_at

  belongs_to :event, serializer: EventSerializer do
    link(:related) { api_v1_event_path(object.event_id) }
  end
  belongs_to :member, serializer: MemberPreviewSerializer do
    link(:related) { api_v1_member_path(object.member_id) }
  end
end
