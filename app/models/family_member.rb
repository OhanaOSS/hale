class FamilyMember < ApplicationRecord
  belongs_to :family
  belongs_to :member
  
  enum :user_role => [:user, :moderator, :admin, :owner]

  validates_presence_of :member_id
  validates_presence_of :family_id
  validates_presence_of :user_role 

end