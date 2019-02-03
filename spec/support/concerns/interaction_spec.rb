require 'rails_helper'

RSpec.shared_examples_for "interaction" do
  let(:model) { described_class } # the class that includes the concern

  before do
    @family = FactoryBot.create(:family)
    @family_members = FactoryBot.create_list(:family_member, 2, family_id: @family.id, authorized_at: DateTime.now)
    
    # This member creates the subject, will recieve notifications.
    @subject_member = @family_members.first.member
    
    # This member will send a notification from reacting to content.
    @subject_reactor = @family_members.second.member

    if model == Comment
        @parent = FactoryBot.create(:post, family_id: @family.id, member_id: @subject_member.id)
        @parent_class = @parent.class.to_s
        @subject = FactoryBot.create(:comment, commentable_type: @parent_class, commentable_id: @parent.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
    elsif model == Recipe
        @subject = FactoryBot.create(:recipe, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
    elsif model == Post
        @subject = FactoryBot.create(:post, family_id: @family.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
    elsif model == Event
        @subject = FactoryBot.create(:event, family_id: @family.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
    elsif model == CommentReply
        top_level = FactoryBot.create(:post, family_id: @family.id, member_id: @subject_member.id)
        @parent = FactoryBot.create(:comment, commentable_type: "Post", commentable_id: @parent.id, member_id: @subject_member.id)
        @subject = FactoryBot.create(:comment_reply, comment_id: @parent.id, member_id: @subject_member.id)
        @subject_class = @subject.class.to_s
    end
  end

  context 'Basic Model Tests' do
    describe ':: Form' do
      it 'expects all fields to be present' do
        expect(Reaction.new).to_not be_valid
      end
      it 'expects id to not be nil or blank' do
        expect(Reaction.new(id: nil)).to_not be_valid
        expect(Reaction.new(id: "")).to_not be_valid
      end
      it 'expects notifiable_type to not be nil or blank' do
        expect(Reaction.new(interaction_type: nil)).to_not be_valid
        expect(Reaction.new(interaction_type: "")).to_not be_valid
      end
      it 'expects notifiable_id to not be nil or blank' do
        expect(Reaction.new(interaction_id: nil)).to_not be_valid
        expect(Reaction.new(interaction_id: "")).to_not be_valid
      end
      it 'expects member_id to not be nil or blank' do
        expect(Reaction.new(member_id: nil)).to_not be_valid
        expect(Reaction.new(member_id: "")).to_not be_valid
      end
    end
    describe ':: Function' do
      it 'the association works' do
        expect {@subject.reactions}.to_not raise_error
      end
      it 'creates the notification on save' do
        Notification.delete_all
        @comparable = FactoryBot.build(:reaction, interaction_type: @subject_class, interaction_id: @subject.id, member_id: @subject_reactor.id)
        expect {@comparable.save}.to change{Notification.count}.by(1)
      end
      it 'creates the reaction on save' do
        Notification.delete_all
        @comparable = FactoryBot.build(:reaction, interaction_type: @subject_class, interaction_id: @subject.id, member_id: @subject_reactor.id)
        expect {@comparable.save}.to change{Reaction.count}.by(1)
      end
      it 'create the reaction and matches expectation' do
        expected = FactoryBot.create(:reaction, interaction_type: @subject_class, interaction_id: @subject.id, member_id: @subject_reactor.id)
        expect(expected).to eq(Reaction.last)
      end
    end
  end
end # Test End
