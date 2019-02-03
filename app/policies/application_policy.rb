class ApplicationPolicy
  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user   = current_user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(current_user, record.class)
  end
  
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      # raise Pundit::NotAuthorizedError, "must be logged in" unless current_user
      @current_user = current_user
      @scope = scope
    end
    def resolve
      scope
    end
  end
  def is_owner?(family_id, member)
    member.family_members.exists?(user_role: "owner", family_id: family_id)
  end
  def is_admin?(family_id, member)
    member.family_members.exists?(user_role: "admin", family_id: family_id)
  end
  def is_moderator?(family_id, member)
    member.family_members.exists?(user_role: "moderator", family_id: family_id)
  end
  def is_authorized_for_family_admin_activity?(family_id, member)
    if record.user_role == "owner"
      is_owner?(family_id, member)
    elsif record.user_role == "admin"
      is_admin?(family_id, member) || is_owner?(family_id, member)
    elsif record.user_role == "moderator"
      is_admin?(family_id, member) || is_owner?(family_id, member)
    elsif record.user_role == "user"
      is_admin?(family_id, member) || is_owner?(family_id, member)
    end
  end
  def does_current_user_and_record_member_id_share_family?(current_user, record_member)
    i = 0
    record_member.family_ids.each { |id| i = i + 1 if current_user.family_ids.include?(id) }
    false if i === 0
    true if i >= 1
  end
end
