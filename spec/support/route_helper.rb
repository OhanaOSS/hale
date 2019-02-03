
module ResourceHelper
  
  def get_prev_family_resource(id, resource)
    target = resource.constantize.find(id)
    scope = get_scope(id, resource)

    target.where(["id > ?", id]).first # id must be scoped
  end

  def get_next_family_resource
    target = resource.constantize.find(id)
    scope = get_scope(id, resource)

    target.where(["id < ?", id]).first # id must be scoped
  end

  def get_scope(id, resource)

    polymorphic = [Notification, Comment, Reaction].detect { |i| self.class == i }
    standard = [FamilyMember, Member, Post, Event, Recipe, CommentReply, EventRsvp].detect { |i| self.class == i }
    if polymorphic
      parent_klass = get_polymorphic_klass(resource)
    elsif standard
      parent_klass = self.class
    end
  end
  
  def get_polymorphic_klass(target)
    # It cycles through each key looking for a match to `_type` and returns it once found.
    target.attributes.each_key do |i|
     return i.slice(0..-6) if i.match?(/[A-z]+_type/)
    end
  end
end