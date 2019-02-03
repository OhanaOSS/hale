module Notifiable
  extend ActiveSupport::Concern

  included do

    has_many :notifications, :as => :notifiable

    after_commit :notify_members, unless: Proc.new { self.class == Member }
  end

  def notify_members
    @parent_klass = [Post, Event, Recipe].detect { |i| self.class == i }
    @child_klass = [Comment, CommentReply, Reaction, EventRsvp].detect { |i| self.class == i }

    # This is the object storing a string of the polymorphic klass for member lookup. (i.e. if the target is Comment then the attribute will be "commentable".)
    @target_attribute_polymorphic_klass = get_polymorphic_klass(self)

    get_parent_and_target
    if self.class == @parent_klass # If it's a parent_klass, notify mentioned members.
      notify_mentioned_members if self.mentioned_members.any?
    elsif @child_klass == Reaction || EventRsvp
      Notification.create(notifiable_type: @target.class.to_s, notifiable_id: @target.id, member_id: @parent.member_id)
    elsif self.class == @child_klass # If it's an child_klass, notify: mentioned members, parent_klass member (if not mentioned), and sibling child_klass.
      notify_mentioned_members if self.mentioned_members.any?
      notify_sibilings if @child_klass == Comment || @child_klass == CommentReply

      if mentioned_members.exclude?(@parent.member_id)
        Notification.create(notifiable_type: @target.class.to_s, notifiable_id: @target.id, member_id: @parent.member_id)
      end
    end
  end

  def notify_sibilings
    if @child_klass == CommentReply
      sibilings_member_ids = CommentReply.where(comment_id: self.comment_id).where.not(member_id: self.member_id).pluck(:member_id).uniq
    else # Polymorphic
      sibilings_member_ids = self.class.where("#{@target_attribute_polymorphic_klass}_type": @parent.class.to_s, "#{@target_attribute_polymorphic_klass}_id": @parent.id).where.not(member_id: self.member_id).pluck(:member_id).uniq
    end

    sibilings_member_ids.each do |sibilings_member_id|
      Notification.where(notifiable_type: @target.class.to_s, notifiable_id: @target.id, member_id: sibilings_member_id).first_or_create unless sibilings_member_id == @target.member_id
    end
  end

  def notify_mentioned_members
    # If there are mentions in the target then there will be an iteration over each mention 
    # and if the parent is not mentioned then they will recieve a notification.
    # If there are no mentions then the parent is notified.
    @mentioned_members_id_array = @target.mentioned_members.uniq.pluck(:id)
    if @mentioned_members_id_array.any? # Are there any mentions?
      @mentioned_members_id_array.each do |member_id|
        Notification.create(notifiable_type: @target.class.to_s, notifiable_id: @target.id, member_id: member_id, mentioned: true)
      end
    end
    return @mentioned_members_id_array

  end

  def get_parent_and_target
      # The target is the ActiveRecord that is Notifiable after it's been committed to the database.
      # The parent is the Active Record of target and is used to notify the Ancestors.
      @target = self
      if @parent_klass
        @parent = self
      elsif @child_klass
        if @child_klass == CommentReply
          @parent = Comment.find(@target.comment_id)
        elsif @child_klass == EventRsvp
          @parent = Event.find(@target.event_id)
        else # Polymorphic Comment or Reaction
          @parent = self["#{@target_attribute_polymorphic_klass.downcase}_type"].constantize.where(id:self["#{@target_attribute_polymorphic_klass.downcase}_id"]).first
        end
      end
  end

  # This method gets the polymorphic class attribute from the active record passed to it. 
  def get_polymorphic_klass(target)
    # It cycles through each key looking for a match to `_type` and returns it once found.
    target.attributes.each_key do |i|
     return i.slice(0..-6) if i.match?(/[A-z]+_type/)
    end
  end

end
