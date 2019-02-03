require 'rails_helper'

RSpec.describe FamilyConfig, type: :model do
  subject { described_class.new }
  let(:subject_family) { FactoryBot.build(:family) }
  describe "Associations" do
    it { should belong_to(:family) }
  end
  describe 'Valid' do
    describe 'and present ::' do
      it { should validate_presence_of(:family_id) }
    end
    describe ':: Basic Validity' do
      it 'should have a family_id attached' do
        subject.family_id = FactoryBot.create(:family).id
        subject.authorization_enabled = true
        expect(subject).to be_valid
      end
      it 'should have a family_id attached and allow authorization_enabled to be false' do
        subject.family_id = FactoryBot.create(:family).id
        subject.authorization_enabled = false
        expect(subject).to be_valid
      end
    end
  end
  describe 'Invalid' do
    describe 'Basic Validity' do
      it 'is not valid at new' do
        expect(subject).to_not be_valid
      end
      it 'is not valid without family_id being an integer' do
        subject.family_id = "two"
        expect(subject).to_not be_valid
      end
      it 'is not valid without authorization_enabled being true/false' do
        subject.authorization_enabled = nil
        expect(subject).to_not be_valid
      end
    end
  end
  describe 'Subject' do
    it 'is created after Family is created' do
      expect {subject_family.save}.to change{described_class.count}.from(0).to(1)
    end
  end
end
