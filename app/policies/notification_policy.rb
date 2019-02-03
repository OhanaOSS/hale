class NotificationPolicy < ApplicationPolicy

  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def unviewed?
    @current_user
  end

  def all?
    @current_user
  end

  class Scope < Scope
    def resolve
      unless current_user == nil
        records = Notification.where(member_id: current_user.id)
        records # return the records
      end
    end # resolve 
  end # Scope

end
