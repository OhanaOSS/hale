class Post < ApplicationRecord
  include Interaction
  include Commentable
  include Notifiable
  has_paper_trail

  belongs_to :family
  belongs_to :member
  has_one_attached :media

  validate :validate_location
  validates :body, presence: true, length: { minimum: 1 }, 
    format: { 
      with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, 
      message: "only allows letters and \"'-.!?;" 
    }, unless: Proc.new { (self.body.present? == true && self.media.attached? == true) || self.media.attached? }, on: :create
    
  validates_presence_of :family_id
  validates_presence_of :member_id
  validates :locked, inclusion: { in: [ true , false ] }, exclusion: { in: [nil] }

  def validate_location
    # Resource: https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude
    # If it's nil or blank it's valid.
    return true if location.nil? || location.blank?

    # There is 1 item in the array it's invalid.
    errors.add(:location, :invalid) if location.size == 1

    # Location must be in array format of [Float, Float]
    if !location.is_a?(Array) && !location[0].is_a?(Float) && !location[1].is_a?(Float)
      errors.add(:location, :invalid)
    end
    # Iterate over each float.
    location.each do | float |
      str_float = float.to_s
      # Regex test for 1-3 characters before period and 2-15 characters after
      # with potential + or - .
      unless float === 0.0
        errors.add(:location, :invalid) unless /[+-]?[0-9]{1,3}.[0-9]{2,15}/.match(str_float)
        # Split digits and decimals.
        split = str_float.split('.')
        # Remove sign if present.
        split[0] = split[0].slice(1..-1) if /[+-][0-9]{1,3}/.match(split[0])
        # Digits must range -180 to 180.
        errors.add(:location, :invalid) unless split.first.to_i <= 180 && split.first.to_i >= -180
        # Decimals must be between 2-15 in length
        errors.add(:location, :invalid) unless split.last.to_i.size >= 2 && split.last.size <= 15
      end
    end
  end

  def mentioned_members
    MentionParser.new(body).members
  end
end
