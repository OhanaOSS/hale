class FamilyConfig < ApplicationRecord
  attr_readonly :id, :family_id

  belongs_to :family

  validates :family_id, presence: true, numericality: { only_integer: true }
  validates :authorization_enabled, inclusion: { in: [ true , false ] }, exclusion: { in: [nil] }

end
