require "rails_helper"

RSpec.describe InviteMailer, type: :mailer do
  describe 'Existing Member' do
    before do
      @sender = FactoryBot.create(:family_member)
      @recipient = FactoryBot.create(:family_member)
      @invite = FactoryBot.create(:invite, email: @recipient.member.email, family_id: @sender.family_id, sender_id: @sender.member_id, recipient_id: @recipient.member_id)
      @family_name = Family.find(@sender.family_id).family_name
    end

    let(:mail) { described_class.existing_user_invite(@invite).deliver }

    it 'renders the subject' do
      expect(mail.subject).to eq("You've been invited by #{@sender.member.name.capitalize} to join the #{@family_name} family on FamNet!")
    end
    it 'renders the recipient email' do
      expect(mail.to).to eq([@recipient.member.email])
    end
    it 'renders the sender email' do
      expect(mail.from).to eq(["invites-no-reply@example.com"])
    end
    it 'assigns family name' do
      expect(mail.body.encoded).to match(@family_name)
    end
  end
  describe 'New Member' do
    before do
      @sender = FactoryBot.create(:family_member)
      @invite = FactoryBot.create(:invite, family_id: @sender.family_id, sender_id: @sender.member_id)
      @family_name = Family.find(@sender.family_id).family_name
    end

    let(:mail) {InviteMailer.new_user_invite(@invite, new_api_v1_member_registration_url(:invite_token => @invite.token)).deliver}

    it 'renders the subject' do
      expect(mail.subject).to eq("You've been invited by #{@sender.member.name.capitalize} to join the #{@family_name} family on FamNet!")
    end
    it 'renders the recipient email' do
      expect(mail.to).to eq([@invite.email])
    end
    it 'renders the sender email' do
      expect(mail.from).to eq(["invites-no-reply@example.com"])
    end
    it 'assigns family name' do
      expect(mail.body.encoded).to match(@family_name)
    end
    it 'assigns @registration_url' do
      expect(mail.body.encoded)
        .to include(Rails.application.routes.url_helpers
          .new_api_v1_member_registration_url(:invite_token => @invite.token))
    end
  end
end