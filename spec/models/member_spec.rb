require 'rails_helper'

RSpec.describe Member, type: :model do
  subject { described_class.new }
  describe "Associations" do
    it { should have_many(:recipes) }
    it { should have_many(:family_members) }
    it { should have_many(:families) }
    it { should have_many(:events) }
    it { should have_many(:event_rsvps) }
    it { should have_many(:posts) }
    it { should have_many(:comments) }
    it { should have_many(:notifications) }
    it { should have_many(:invitations) }
    it { should have_many(:sent_invites) }
  end

  describe 'Valid' do
    it 'and the Factory should work' do
      subject = FactoryBot.build(:member)
      expect(subject).to be_valid
    end
    describe 'and present ::' do
      it { should validate_presence_of(:provider) }
      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:surname) }
      it { should validate_presence_of(:email) }
    end
    describe 'and Basic Validations' do
      it { should define_enum_for(:gender).with([:female, :male, :nonbinary]) }
      it { should validate_length_of(:bio).is_at_most(500).on(:create) }
      it { should validate_length_of(:name).is_at_least(1).on(:create) }
      it { should validate_length_of(:surname).is_at_least(1).on(:create) }
      it { should validate_length_of(:email).is_at_least(5).on(:create) }
    end
    describe 'Basic Validity' do
      it 'is with name, surname, email, and password' do
        subject.name = "First"
        subject.surname = "Last"
        subject.email = "foobar@gmail.com"
        subject.password = "password"
        expect(subject).to be_valid
      end
    end
  end
  describe 'Invalid' do
    describe 'Basic Validity' do
      it 'is not valid at new' do
        expect(subject).to_not be_valid
      end
      it 'is not valid without surname' do
        subject.name = "First"
        expect(subject).to_not be_valid
      end
      it 'is not valid without email' do
        subject.name = "First"
        subject.surname = "Last"
        expect(subject).to_not be_valid
      end
      it 'is not valid without password' do
        subject.name = "First"
        subject.surname = "Last"
        subject.email = "foobar@gmail.com"
        expect(subject).to_not be_valid
      end
    end
    describe 'Column Formats' do
      it 'Contacts is not valid unless hash' do
        subject = FactoryBot.build(:member)
        subject.contacts = []
        expect(subject).to_not be_valid
      end
      it 'Addresses is not valid unless hash' do
        subject = FactoryBot.build(:member)
        subject.addresses = []
        expect(subject).to_not be_valid
      end
    end
  end
  describe 'Avatar validation' do
    describe ':: Attaching' do
      before(:each) do
        @avatar_subject = FactoryBot.build(:member)
      end
      it 'saves the image' do
        @avatar_subject.save!        
        expect(@avatar_subject.avatar).to_not be_attached
        @avatar_subject.avatar.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
        expect(@avatar_subject.avatar.instance_of?(ActiveStorage::Attached::One)).to be_truthy
        expect(@avatar_subject.avatar).to be_attached
      end
      it "the attachment record should match #{described_class.to_s.downcase}'s record'" do
        @avatar_subject.save!        
        @avatar_subject.avatar.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
        expect(@avatar_subject.avatar.attachment.record_id).to eq(@avatar_subject.id)
        expect(@avatar_subject.avatar.attachment.record_type).to eq(@avatar_subject.class.to_s)
        expect(@avatar_subject.avatar.blob.instance_of?(ActiveStorage::Blob)).to be_truthy
      end
    end
    describe ':: Validations' do
      it 'should be valid without avatar and have a default avatar' do
        subject = FactoryBot.build(:member, avatar: nil)
        expect(subject).to be_valid
        expect(subject.avatar.attached?).to be_falsey
      end
      it 'should be valid with avatar' do
        subject = FactoryBot.build(:member, avatar: fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg'))
        expect(subject).to be_valid
        expect(subject.avatar.attached?).to be_truthy
      end
    end
  end
end
