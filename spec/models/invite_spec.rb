require 'rails_helper'

RSpec.describe Invite, type: :model do
  describe "Associations" do
    it { should belong_to(:sender).class_name('Member') }
    it { should belong_to(:family) }
  end

  describe '::invalids' do
    it "is invalid with invalid attributes" do
      expect(Invite.new).to_not be_valid
    end

    describe 'nils' do
      it "is not valid without a email" do
        invite = Invite.new(email: nil)
        expect(invite).to_not be_valid
      end

      it "is not valid without a family_id" do
        invite = Invite.new(family_id: nil)
        expect(invite).to_not be_valid
      end

      it "is not valid without a sender_id" do
        invite = Invite.new(sender_id: nil)
        expect(invite).to_not be_valid
      end
    end
    describe 'type' do
      it "is not valid with a email being an int" do
        invite = Invite.new(email: 1)
        expect(invite).to_not be_valid
      end
      it "is not valid with family_id as string number spelled out" do
        invite = Invite.new(family_id: "one")
        expect(invite).to_not be_valid
      end
      it "is not valid without a family_id" do
        invite = Invite.new(family_id: "1")
        expect(invite).to_not be_valid
      end

      it "is not valid with sender_id as string number spelled out" do
        invite = Invite.new(sender_id: "one")
        expect(invite).to_not be_valid
      end
      it "is not valid with sender_id as int as string" do
        invite = Invite.new(sender_id: "1")
        expect(invite).to_not be_valid
      end
    end
    describe 'association relationships' do
      it 'sender_id and family_id must belong to the same family' do
        family_id = FactoryBot.create(:family_member).family_id
        sender_id = FactoryBot.create(:family_member).member_id
        invite = Invite.new(email: "test@test-example.com", sender_id: sender_id, family_id: family_id)
        expect(invite).to_not be_valid
      end
    end
  end
  describe '::valids' do
      it "must have email, sender_id, and family_id" do
        user = FactoryBot.create(:family_member)
        invite = Invite.new(email: "test@test-example.com", sender_id: user.member_id, family_id: user.family_id)
        expect(invite).to be_valid
      end
  end
end
