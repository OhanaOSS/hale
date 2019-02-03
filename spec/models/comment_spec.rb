require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "Associations" do
    it { should have_many(:notifications) }
    it { should have_many(:comment_replies) }
    it { should have_many(:reactions) }
    it { should belong_to(:commentable) }
    it { should belong_to(:member) }
  end
  it_behaves_like 'media'
  it_behaves_like 'notifiable'
  it_behaves_like 'interaction'
  describe "Post Subject" do
    before do
      @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @member_id = @family_member.member_id
      @subject = FactoryBot.create(:post, family_id: @family_member.family_id, member_id: @member_id)
      @subject_class = @subject.class.to_s
    end
    describe "valid" do
      it 'FactoryBot factory should be valid' do
        expect(FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id) ).to be_valid
      end
      describe ":: nils" do
        it "all nils should be valid :: edit" do
          comment = FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id, edit: nil)
          expect(comment).to be_valid
        end
      end
    end
    describe "invalid" do
      it "empty new should be invalid" do
        expect(Comment.new).to_not be_valid
      end
      describe ":: nils" do
        it "all nils should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: member_id" do
          comment = Comment.new(member_id: nil)
          expect(comment).to_not be_valid
        end
      end
      describe ":: emptys" do
        it "all emptys should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: member_id" do
          comment = Comment.new(member_id: "")
          expect(comment).to_not be_valid
        end
      end
    end
  end
  describe "Recipe Subject" do
    before do
      @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @member_id = @family_member.member_id
      @subject = FactoryBot.create(:recipe, member_id: @member_id)
      @subject_class = @subject.class.to_s
    end
    describe "valid" do
      it 'FactoryBot factory should be valid' do
        expect(FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id) ).to be_valid
      end
      describe ":: nils" do
        it "all nils should be valid :: edit" do
          comment = FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id, edit: nil)
          expect(comment).to be_valid
        end
      end
    end
    describe "invalid" do
      it "empty new should be invalid" do
        expect(Comment.new).to_not be_valid
      end
      describe ":: nils" do
        it "all nils should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: member_id" do
          comment = Comment.new(member_id: nil)
          expect(comment).to_not be_valid
        end
      end
      describe ":: emptys" do
        it "all emptys should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: member_id" do
          comment = Comment.new(member_id: "")
          expect(comment).to_not be_valid
        end
      end
    end
  end
  describe "Event Subject" do
    before do
      @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @member_id = @family_member.member_id
      @subject = FactoryBot.create(:event, family_id: @family_member.family_id, member_id: @member_id)
      @subject_class = @subject.class.to_s
    end
    describe "valid" do
      it 'FactoryBot factory should be valid' do
        expect(FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id) ).to be_valid
      end
      describe ":: nils" do
        it "all nils should be valid :: edit" do
          comment = FactoryBot.build(:comment, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id, edit: nil)
          expect(comment).to be_valid
        end
      end
    end
    describe "invalid" do
      it "empty new should be invalid" do
        expect(Comment.new).to_not be_valid
      end
      describe ":: nils" do
        it "all nils should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: nil)
          expect(comment).to_not be_valid
        end
        it "all nils should be invalid :: member_id" do
          comment = Comment.new(member_id: nil)
          expect(comment).to_not be_valid
        end
      end
      describe ":: emptys" do
        it "all emptys should be invalid :: body" do
          comment = Comment.new(body: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_type" do
          comment = Comment.new(commentable_type: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: commentable_id" do
          comment = Comment.new(commentable_id: "")
          expect(comment).to_not be_valid
        end
        it "all emptys should be invalid :: member_id" do
          comment = Comment.new(member_id: "")
          expect(comment).to_not be_valid
        end
      end
    end
  end
  describe 'body - media validation' do
    before do
      @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @member_id = @family_member.member_id
      @subject = FactoryBot.create(:post, family_id: @family_member.family_id, member_id: @member_id)
      @subject_class = @subject.class.to_s
    end
    it 'should not be valid if body is missing and media is missing' do
      subject = FactoryBot.build(:comment, body: nil, media: nil, commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id)
      expect(subject).to_not be_valid
      expect(subject.media.attached?).to be_falsey
    end
    it 'should be valid if media is present and body is not' do
      subject = FactoryBot.build(:comment, body: nil, media: fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg'), commentable_type: @subject_class, commentable_id: @subject.id, member_id: @member_id)
      expect(subject).to be_valid
      expect(subject.media.attached?).to be_truthy
    end
  end
end
