require 'rails_helper'

RSpec.describe CommentReply, type: :model do
  describe "Associations" do
    it { should have_many(:notifications) }
    it { should have_many(:reactions) }
    it { should belong_to(:comment) }
    it { should belong_to(:member) }
  end
  before do
    @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
    @member_id = @family_member.member_id
    @parent = FactoryBot.create(:post, family_id: @family_member.family_id, member_id: @member_id)
    @parent_class = @parent.class.to_s
    @subject = FactoryBot.create(:comment, commentable_type: @parent_class, commentable_id: @parent.id, member_id: @member_id)
  end
  it_behaves_like 'interaction'
  it_behaves_like 'notifiable'
  describe "valid" do
    it 'FactoryBot factory should be valid' do
      expect(FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @member_id) ).to be_valid
    end
  end
  describe "invalid" do
    it "empty new should be invalid" do
      expect(CommentReply.new).to_not be_valid
    end
    describe ":: nils" do
      it "all nils should be invalid :: body" do
        comment_reply = CommentReply.new(body: "")
        expect(comment_reply).to_not be_valid
      end
      it "all nils should be invalid :: comment_id" do
        comment_reply = CommentReply.new(comment_id: nil)
        expect(comment_reply).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        comment_reply = CommentReply.new(member_id: nil)
        expect(comment_reply).to_not be_valid
      end
    end
    describe ":: emptys" do
      it "all emptys should be invalid :: body" do
        comment_reply = CommentReply.new(body: "")
        expect(comment_reply).to_not be_valid
      end
      it "all nils should be invalid :: comment_id" do
        comment_reply = CommentReply.new(comment_id: nil)
        expect(comment_reply).to_not be_valid
      end
      it "all emptys should be invalid :: member_id" do
        comment_reply = CommentReply.new(member_id: "")
        expect(comment_reply).to_not be_valid
      end
    end
  end
end
