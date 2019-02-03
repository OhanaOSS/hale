require 'rails_helper'

RSpec.describe Family, type: :model do
  subject { described_class.new }
  describe "Associations" do
    it { should have_many(:family_members) }
    it { should have_many(:members) }
    it { should have_many(:posts) }
    it { should have_many(:events) }
    it { should have_one(:family_config) }
    it { should have_many(:invites) }
  end

  describe 'Valid' do
    it 'and the Factory should work' do
      subject = FactoryBot.build(:family)
      expect(subject).to be_valid
    end
    describe 'and present ::' do
      it { should validate_presence_of(:family_name) }
    end
    describe 'Basic Validity' do
      it 'is with member_id, family_id, and user_role' do
        subject.family_name = "Last-name"
        expect(subject).to be_valid
      end
      it 'is with member_id, family_id, user_role (user), and authorized_at' do
        subject.family_name = "Last"
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
      it 'is not valid without family name (blank)' do
        subject.family_name = nil
        expect(subject).to_not be_valid
      end
      it 'is not valid without family name (nil)' do
        subject.family_name = ""
        expect(subject).to_not be_valid
      end
    end
  end
  describe 'Create FamilyConfig' do
    it 'after Family is created' do
      family = FactoryBot.build(:family)
      expect {family.save}.to change{FamilyConfig.count}.from(0).to(1)
    end
  end
end
