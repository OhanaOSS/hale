class EventPolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def index?
    @current_user
  end

  def show?
    @current_user
    does_current_user_and_record_member_id_share_family?(@current_user, @record.member)
  end

  def create?
    record_members_family_ids = FamilyMember.where(member_id: record.member_id).where.not(authorized_at: nil).pluck(:family_id)
    auth = FamilyMember.where(family_id: record_members_family_ids, member_id: current_user.id).where.not(authorized_at: nil)
    unless auth.empty?
      true
    else
      false
    end
  end

  def update?
    record_family_id_scope = FamilyMember.where(member_id: record.member_id).pluck(:family_id)
    current_user.id == record.member_id || (is_moderator?(record_family_id_scope, current_user) || is_admin?(record_family_id_scope, current_user))
  end

  def destroy?
    record_family_id_scope = FamilyMember.where(member_id: record.member_id).pluck(:family_id)
    current_user.id == record.member_id || is_admin?(record_family_id_scope, current_user)
  end

  class Scope < Scope

      def resolve
        unless current_user == nil
          records = scope.where(family_id: current_user.families.pluck(:id))
          records
        end # current_user = nil
        records
      end

  end
end

