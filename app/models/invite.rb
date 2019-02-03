class Invite < ApplicationRecord

  belongs_to :family
  belongs_to :sender, :class_name => 'Member'
  belongs_to :recipient, :class_name => 'Member', optional: true
  
  before_create :generate_token
  before_save :check_user_existence
  after_save :create_family_member,
    unless: Proc.new { |invite| invite.recipient_id.nil? }

  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, message: "invalid email format" }, length: { minimum: 1 }
  validate :sender_and_family_id_are_same?

  def sender_and_family_id_are_same?
    if sender_id.present? && family_id.present?
    errors.add(:family_id, "family_id and sender_id do not share the same family.") unless Member.find(sender_id).family_ids.include?(family_id)
    else
      errors.add(:family_id, :invalid) unless family_id.present?
      errors.add(:sender_id, :invalid) unless sender_id.present? 
    end
  end

  def check_user_existence
      recipient = Member.find_by_email(email)
    if recipient
        self.recipient_id = recipient.id
    end
  end

  def generate_token
    self.token = Digest::SHA1.hexdigest([self.family_id, Time.now, rand].join)
  end  
  
  def create_family_member
    FamilyMember.find_or_create_by(family_id: family_id, member_id: recipient_id)
    # self.token = nil
    # self.accepted_at = DateTime.now
  end

end
