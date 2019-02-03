class InvitePolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def create?
    current_user.family_members.pluck(:family_id).include?(@record.family_id)
  end
  class Scope < Scope
    def resolve
      scope
    end
  end
end
