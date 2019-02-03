class Family < ApplicationRecord
  has_many :family_members, dependent: :destroy
  has_many :members, through: :family_members
  has_many :posts, dependent: :destroy
  has_many :events, dependent: :destroy
  has_one :family_config, dependent: :destroy

  has_many :invites
  
  validates :family_name, presence: true, format: { with: /\A\w[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s'-]+\z/, message: "only allows letters" }, length: { minimum: 1 }
  after_commit :spin_up_family_dependents

  def spin_up_family_dependents
    config = FamilyConfig.new(family_id: id)
    config.save
  end

end
