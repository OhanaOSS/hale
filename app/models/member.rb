class Member < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :recipes
  has_many :family_members, dependent: :destroy
  has_many :families, through: :family_members
  has_many :events
  has_many :event_rsvps
  has_many :posts
  has_many :comments
  has_many :notifications

  has_many :invitations, :class_name => "Invite", :foreign_key => 'recipient_id'
  has_many :sent_invites, :class_name => "Invite", :foreign_key => 'sender_id'

  has_one_attached :avatar, dependent: :destroy

  enum :gender => [:female, :male, :nonbinary]

  validates_presence_of :provider
  validates :name, presence: true, format: { with: /\A\w[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s'-]+\z/, message: "only allows letters" }, length: { minimum: 1 }
  validates :nickname, allow_blank: true, format: { with: /\A\w[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s'-]+\z/, message: "only allows letters" }, length: { minimum: 1 }
  validates :surname, presence: true, format: { with: /\A\w[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s'-]+\z/, message: "only allows letters" }, length: { minimum: 1 }
  # Regex is from http://guides.rubyonrails.org/active_record_validations.html
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, message: "invalid email format" }, length: { minimum: 5 }
  validates :bio, allow_blank: true, length: { maximum: 500 }
  validates :gender, allow_blank: true, inclusion: { in: genders.keys }
  validate :validates_hash_columns

  def validates_hash_columns
    unless contacts.is_a?(Hash) || contacts == "{}"
      errors.add(:contacts, :invalid)
    end
    unless addresses.is_a?(Hash) || addresses == "{}"
      errors.add(:addresses, :invalid)
    end
  end # validates_hash_columns
end
