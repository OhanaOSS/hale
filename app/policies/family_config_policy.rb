class FamilyConfigPolicy < ApplicationPolicy

  def initialize(current_user, record)
    @current_user   = current_user
    @record = record
  end

  def show?
    is_owner?(record.family_id, current_user)
  end

  def update?
    is_owner?(record.family_id, current_user)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
