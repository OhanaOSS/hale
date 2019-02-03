require 'rails_helper'

RSpec.describe EventRsvp, type: :model do
  describe "Associations" do
    it { should have_many(:notifications) }
    it { should belong_to(:event) }
    it { should belong_to(:member) }
  end
  describe 'Basic Validations' do
    it { should define_enum_for(:rsvp).with([:no, :yes, :maybe ]) }
  end
  before do
    @family_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
    @member_id = @family_member.member_id
    @family_id = @family_member.family_id
    @recipe_example = FactoryBot.create(:recipe, member_id: @member_id)
    @subject = FactoryBot.create(:event, family_id: @family_id, member_id: @member_id)
  end
  it_behaves_like 'notifiable'
  before(:each) do
    @comparable = FactoryBot.build(:event_rsvp, party_size: 1, rsvp: 1, bringing_food: true, recipe_id: @recipe_example.id, serving: 5, event_id: @subject.id, member_id: @member_id, party_companions: [])
  end
  describe "valid" do
    it 'array of party companions should be allowed with array with values' do
      @comparable.party_companions << 1
      expect(@comparable).to be_valid
    end
    describe ':: blanks that are allowed:' do
      it 'non_recipe_description to be blank' do
        @comparable.non_recipe_description = ""
        expect(@comparable).to be_valid
      end
      it 'party_companions to be blank' do
        @comparable.party_companions = ""
        expect(@comparable).to be_valid
      end
      it 'rsvp_note to be blank' do
        @comparable.rsvp_note = ""
        expect(@comparable).to be_valid
      end
      it 'recipe_id to be blank' do
        @comparable.recipe_id = ""
        expect(@comparable).to be_valid
      end
    end
    describe ':: nils that are allowed:' do
      it 'non_recipe_description to be blank' do
        @comparable.non_recipe_description = nil
        expect(@comparable).to be_valid
      end
      it 'party_companions to be blank' do
        @comparable.party_companions = nil
        expect(@comparable).to be_valid
      end
      it 'rsvp_note to be blank' do
        @comparable.rsvp_note = nil
        expect(@comparable).to be_valid
      end
      it 'recipe_id to be nil' do
        @comparable.recipe_id = nil
        expect(@comparable).to be_valid
      end
    end
  end
  describe "invalid" do
    it "empty new should be invalid" do
      expect(EventRsvp.new).to_not be_valid
    end
    describe ":: nils" do
      it "all nils should be invalid :: party_size" do
        @comparable.party_size = nil
        expect(@comparable).to_not be_valid
      end
      it "all nils should be invalid :: event_id" do
        @comparable.event_id = nil
        expect(@comparable).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        @comparable.member_id = nil
        expect(@comparable).to_not be_valid
      end
    end
    describe ":: emptys" do
      it "all blanks/emptys should be invalid :: party_size" do
        @comparable.party_size = ""
        expect(@comparable).to_not be_valid
      end
      it "all blanks/emptys should be invalid :: event_id" do
        @comparable.event_id = ""
        expect(@comparable).to_not be_valid
      end
      it "all blanks/emptys should be invalid :: member_id" do
        @comparable.member_id = ""
        expect(@comparable).to_not be_valid
      end
    end
  end
end
