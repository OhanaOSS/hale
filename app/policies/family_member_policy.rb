class FamilyMemberPolicy < ApplicationPolicy

  def initialize(current_user, record)
    @current_user   = current_user
    @record = record
  end

  def index?
    is_admin?(record.pluck(:family_id).uniq, current_user) || is_owner?(record.pluck(:family_id).uniq, current_user)
  end

  def update?
    is_authorized_for_family_admin_activity?(record.family_id, current_user)
  end

  def destroy?
    is_authorized_for_family_admin_activity?(record.family_id, current_user)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end

