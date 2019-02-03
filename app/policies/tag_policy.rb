class TagPolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def index?
    auth = FamilyMember.where(member_id: current_user.id).where.not(authorized_at: nil)
    auth.any? {|item| !item.authorized_at.nil?}
  end

  def create?
    auth = FamilyMember.where(member_id: current_user.id).where.not(authorized_at: nil)
    auth.any? {|item| !item.authorized_at.nil?}
  end

  def destroy?
    auth = FamilyMember.where(member_id: current_user.id).where.not(authorized_at: nil)
    auth.any? {|item| item.user_role == ("admin" || "owner")}
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
