class FamilyPolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def show?
    current_user.family_ids.include?(record.id)
  end

  def update?
    is_owner?(record.id, current_user)
  end

  def destroy?
    is_owner?(record.id, current_user)
  end

  def invite_to?
    is_owner?(record.id, current_user) || is_admin?(record.id, current_user)
  end

  class Scope < Scope
    def resolve
      unless current_user == nil
        authorized_ids = current_user.family_members.where.not(authorized_at: nil).pluck(:family_id).uniq
        unless authorized_ids.empty?
          records = Member.where(id: FamilyMember.where(family_id: authorized_ids).pluck(:member_id))
          records # return the wikis array we've built up
        else
          records # return the wikis array we've built up
        end
      end
    end #resolve
  end



end
