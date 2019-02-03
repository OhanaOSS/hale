require 'rails_helper'

RSpec.describe FamilyMember, type: :model do
  subject { described_class.new }
  describe "Associations" do
    it { should belong_to(:family) }
    it { should belong_to(:member) }
  end

  describe 'Valid' do
    it 'and the Factory should work' do
      subject = FactoryBot.build(:family_member)
      expect(subject).to be_valid
    end
    describe 'and present ::' do
      it { should validate_presence_of(:member_id) }
      it { should validate_presence_of(:family_id) }
    end
    describe 'and Basic Validations' do
      it { should define_enum_for(:user_role).with([:user, :moderator, :admin, :owner]) }
    end
    describe 'Basic Validity' do
      before(:each) do
        @family = FactoryBot.create(:family)
        @member = FactoryBot.create(:member)
      end
      it 'is with member_id, family_id, and user_role' do
        subject.member_id = @member.id
        subject.family_id = @family.id
        subject.user_role = "user"
        expect(subject).to be_valid
      end
      it 'is with member_id, family_id, user_role (user), and authorized_at' do
        subject.member_id = @member.id
        subject.family_id = @family.id
        subject.user_role = "user"
        subject.authorized_at = DateTime.now
        expect(subject).to be_valid
      end
      it 'is with member_id, family_id, user_role (user), and authorized_at' do
        subject.member_id = @member.id
        subject.family_id = @family.id
        subject.user_role = "moderator"
        subject.authorized_at = DateTime.now
        expect(subject).to be_valid
      end
      it 'is with member_id, family_id, user_role (user), and authorized_at' do
        subject.member_id = @member.id
        subject.family_id = @family.id
        subject.user_role = "admin"
        subject.authorized_at = DateTime.now
        expect(subject).to be_valid
      end
      it 'is with member_id, family_id, user_role (user), and authorized_at' do
        subject.member_id = @member.id
        subject.family_id = @family.id
        subject.user_role = "owner"
        subject.authorized_at = DateTime.now
        expect(subject).to be_valid
      end
    end
  end
  describe 'Invalid' do
    describe 'Basic Validity' do
      before(:each) do
        @family = FactoryBot.create(:family)
        @member = FactoryBot.create(:member)
      end
      it 'is not valid at new' do
        expect(subject).to_not be_valid
      end
      it 'is not valid without family_id' do
        subject.user_role = nil
        subject.member_id = @member.id
        expect(subject).to_not be_valid
      end
      it 'is not valid without family_id' do
        subject.user_role = nil
        subject.member_id = @member.id
        subject.family_id = @family.id
        expect(subject).to_not be_valid
      end
    end
  end
end
