class EventRsvp < ApplicationRecord
  include Notifiable
  has_paper_trail
  belongs_to :member
  belongs_to :event

  enum :rsvp => [ :no, :yes, :maybe ]
  validates :rsvp, inclusion: { in: rsvps.keys }
  validates_presence_of :rsvp
  validates :non_recipe_description, allow_blank: true, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates :rsvp_note, allow_blank: true, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates_presence_of :party_size
  validates_presence_of :event_id
  validates_presence_of :member_id
  validate :validate_party_companions

  def validate_party_companions
    if party_companions.present? && !party_companions.is_a?(Array)
      errors.add(:party_companions, :invalid) unless party_companions != [] 
    end
  end

  def mentioned_members
    MentionParser.new(rsvp_note).members
  end
end
