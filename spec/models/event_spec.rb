require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "Associations" do
    it { should have_many(:reactions) }
    it { should have_many(:comments) }
    it { should belong_to(:family) }
    it { should belong_to(:member) }
  end
  before do
    @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
    @member_id = @family_member.member_id
    @family_id = @family_member.family_id
  end
  before(:each) do
    @comparable = FactoryBot.build(:event, family_id: @family_id, member_id: @member_id)
  end
  it_behaves_like 'media'
  it_behaves_like 'interaction'
  describe "valid" do
    it "all nils should be valid :: location" do
      event = FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: nil)
      expect(event).to be_valid
    end
    describe ":: location formats" do
      it '[+180.01,+0.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [+180.01,+0.01] ) ).to be_valid
      end
      it '[+0.01,+180.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [+0.01,+180.01] ) ).to be_valid
      end
      it '[+90.01,+1.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[+90.01,+1.01] ) ).to be_valid
      end
      it '[-1.01,-90.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[-1.01,-90.01] ) ).to be_valid
      end
      it '[-180.01,0.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[-180.01,0.01] ) ).to be_valid
      end
      it '[0.01,-180.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[0.01,-180.01] ) ).to be_valid
      end
      it '[0.01,0.01] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [0.01,0.01] ) ).to be_valid
      end
      it '[0,0] is valid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [0,0] ) ).to be_valid
      end
    end
  end
  describe "invalid" do
    it "empty new should be invalid" do
      expect(EventRsvp.new).to_not be_valid
    end
    describe ":: location formats" do
      before do
      end
      it '"120.01,1.01" is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:"120.01,1.01" ) ).to_not be_valid
      end
      it '[1111.00,0.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[1111.00,0.00] ) ).to_not be_valid
      end
      it '[0.00,1111.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[0.00,1111.00] ) ).to_not be_valid
      end
      it '[-181.00,-0.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [-181.00,-0.00] ) ).to_not be_valid
      end
      it '[-0.00,-181.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location: [-0.00,-181.00] ) ).to_not be_valid
      end
      it '[180.00,-0.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[180.00,-0.00] ) ).to_not be_valid
      end
      it '[181.00,0.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[181.00,0.00] ) ).to_not be_valid
      end
      it '[0.00,181.00] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[0.00,181.00] ) ).to_not be_valid
      end
      it '[180,180] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[180,180] ) ).to_not be_valid
      end
      it '[180.0,180.0] is invalid' do
        expect(FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, location:[180.0,180.0] ) ).to_not be_valid
      end
    end
    describe ":: nils" do
      it "all nils should be invalid :: title" do
        event = Event.new(title: nil)
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: description" do
        event = Event.new(description: nil)
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: locked" do
        event = Event.new(locked: nil)
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: family_id" do
        event = Event.new(family_id: nil)
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        event = Event.new(member_id: nil)
        expect(event).to_not be_valid
      end
    end
    describe ":: emptys" do
      it "all nils should be invalid :: title" do
        event = Event.new(title: "")
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: description" do
        event = Event.new(description: "")
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: location" do
        event = Event.new(location: "")
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: locked" do
        event = Event.new(locked: "")
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: family_id" do
        event = Event.new(family_id: "")
        expect(event).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        event = Event.new(member_id: "")
        expect(event).to_not be_valid
      end
    end
  end
  describe 'body - media validation' do
    it 'should be valid without media' do
      subject = FactoryBot.build(:event, family_id: @family_id, member_id: @member_id)
      expect(subject).to be_valid
      expect(subject.media.attached?).to be_falsey
    end
    it 'should be valid with media' do
      subject = FactoryBot.build(:event, family_id: @family_id, member_id: @member_id, media: fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg'))
      expect(subject).to be_valid
      expect(subject.media.attached?).to be_truthy
    end
  end
end
