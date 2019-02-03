require 'rails_helper'

RSpec.shared_examples_for "notifiable" do
  let(:model) { described_class } # the class that includes the concern

  before do
    @family = FactoryBot.create(:family)
    @family_members = FactoryBot.create_list(:family_member, 4, family_id: @family.id, authorized_at: DateTime.now)
    
    # This member creates the subject, will recieve notifications, and mention
    # @subject_mentioned_member in the @subject.
    @subject_member = @family_members.first.member
    
    # This member will recieve a notification from being mentioned by
    # @subject_member in the @subject.
    @subject_mentioned_member = @family_members.second.member

    # This member creates the comments or comment_replys and mentions
    # @mentioned_member in the @comparable.
    @mentioning_member = @family_members.third.member

    # This member recieves mentions and notifications.
    @mentioned_member = @family_members.fourth.member



    if model == Comment
        @subject = FactoryBot.create(:post, family_id: @family.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
        @comparable = FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @mentioning_member.id)
        @comparable_class = @comparable.class.to_s
    elsif model == Reaction
        @subject = FactoryBot.create(:post, family_id: @family.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
        @comparable = FactoryBot.build(:reaction, interaction_type: @subject_class, interaction_id: @subject.id, member_id: @member_id)
        @comparable_class = @comparable.class.to_s
    elsif model == Post
        @comparable = FactoryBot.build(:post, family_id: @family.id, member_id: @subject_member.id)
        @comparable_class = @comparable.class.to_s
    elsif model == EventRsvp
        @subject = FactoryBot.create(:event, family_id: @family.id, member_id: @subject_member.id)
        @comparable = FactoryBot.build(:event_rsvp, event_id: @subject.id, member_id: @mentioning_member.id)
        @comparable_class = @comparable.class.to_s
    elsif model == CommentReply
        @comparable = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @mentioning_member.id)
        @comparable_class = @comparable.class.to_s
    end
  end

  context 'Basic Model Tests' do
    describe ':: Form' do
      it 'expects all fields to be present' do
        expect(Notification.new).to_not be_valid
      end
      it 'expects id to not be nil or blank' do
        expect(Notification.new(id: nil)).to_not be_valid
        expect(Notification.new(id: "")).to_not be_valid
      end
      it 'expects notifiable_type to not be nil or blank' do
        expect(Notification.new(notifiable_type: nil)).to_not be_valid
        expect(Notification.new(notifiable_type: "")).to_not be_valid
      end
      it 'expects notifiable_id to not be nil or blank' do
        expect(Notification.new(notifiable_id: nil)).to_not be_valid
        expect(Notification.new(notifiable_id: "")).to_not be_valid
      end
      it 'expects member_id to not be nil or blank' do
        expect(Notification.new(member_id: nil)).to_not be_valid
        expect(Notification.new(member_id: "")).to_not be_valid
      end
      it 'expects mentioned to be false by default' do
        notification = Notification.new
        expect(notification.mentioned).to eq(false)
      end
      it 'expects viewed to be false by default' do
        notification = Notification.new
        expect(notification.viewed).to eq(false)
      end
    end
    describe ':: Function' do
      it 'the association works' do
        expect {@comparable.notifications}.to_not raise_error
      end
      it 'creates the notification on save' do
        skip "Test should not run if the shared model is Post." if model == Post
        Notification.delete_all
        expect {@comparable.save}.to change{Notification.count}.from(0).to(1)
      end
    end
  end
  context 'Mention Integration Tests' do
    it 'creates two notifications when mentioned' do
      skip "Test should not run if the shared model is a Reaction or EventRsvp." if model == Reaction || EventRsvp
      name_to_be_mentioned = @mentioned_member.attributes.slice("name", "surname").values.join(" ").insert(0, "@")
      @comparable.body.insert(-1, name_to_be_mentioned)
      expect{@comparable.save}.to change{Notification.count}.from(0).to(2)
    end
    it 'expects mention notifications to be marked as true' do
      skip "Test should not run if the shared model is a Reaction or EventRsvp." if model == Reaction || EventRsvp
      name_to_be_mentioned = @mentioned_member.attributes.slice("name", "surname").values.join(" ").insert(0, "@")
      @comparable.body.insert(-1, name_to_be_mentioned)
      @comparable.save
      example = @comparable
      expect(example.notifications.first.mentioned).to eq(true)
    end
  end
  context 'Specific Cases' do
    it "a notification record created on @comparable commit for the @subject object's member on model action" do
      skip "Test should not run if the shared model is Post." if model == Post
      Notification.delete_all
      expect{@comparable.save}.to change{Notification.count}.from(0).to(1)
    end
  end # Specific Cases `context`

end # Test End
