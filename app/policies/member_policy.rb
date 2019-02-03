class MemberPolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  # Returns Scope
  def index?
    @current_user
  end

  def show?
    current_user.id == record.id || current_user.family_members.exists?(family_id: record.family_ids) || is_admin?(record.family_ids, current_user)
  end

  def create?
    is_admin?(record.family_id, current_user)
  end

  def update?
    current_user.id == record.id || is_admin?(record.family_ids, current_user)
  end

  def destroy?
    current_user.id == record.id || is_admin?(record.family_ids, current_user)
  end

  class Scope < Scope
    def resolve
      unless current_user == nil
        authorized_ids = current_user.family_members.where.not(authorized_at: nil).pluck(:family_id).uniq
        unless authorized_ids.empty?
          records = Member.where(id: FamilyMember.where(family_id: authorized_ids).pluck(:member_id))
          records # return array we've built up
        else
          records # return array we've built up
        end
      end
    end #resolve

      
  end



end

