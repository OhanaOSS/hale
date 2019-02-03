require 'rails_helper'
# The registration workflow for Invites is tested in
# spec/requests/authentication_and_registration.rb
# under "Signing up :: via email token && registration ::"
RSpec.describe "Invites", type: :request do
  context "Authorized Family Members" do
    before do
      @family_member = FactoryBot.create(:family_member)
      login_auth(@family_member.member)
    end
    describe "POST /invites Invites#create for new members" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
      end
      it "users can invite new members" do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to be_nil
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'moderators can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to be_nil
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'admins can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to be_nil
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'owners can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to be_nil
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
    end
    describe "POST /invites Invites#create for existing member accounts" do
      before do
        @other_family_member = FactoryBot.create(:family_member)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @family_member.member_id, recipient_id: @other_family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
      end
      it "users can invite new members" do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to eq(expected["recipient_id"])
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("recipient")
        expect(relationships["recipient"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'moderators can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to eq(expected["recipient_id"])
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("recipient")
        expect(relationships["recipient"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'admins can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to eq(expected["recipient_id"])
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("recipient")
        expect(relationships["recipient"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
      it 'owners can invite new members' do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        actual = JSON.parse(response.body)["data"]
        expected = @create_invite
        expect(actual["attributes"]["email"]).to eq(expected["email"])
        expect(actual["attributes"]["sender-id"]).to eq(expected["sender_id"])
        expect(actual["attributes"]["recipient-id"]).to eq(expected["recipient_id"])
        expect(actual["attributes"]["family-id"]).to eq(expected["family_id"])
        expect(actual["attributes"]["sent-at"]).to_not be_nil
        expect(response).to have_http_status(200)

        relationships = actual["relationships"]
        expect(relationships).to include("sender")
        expect(relationships["sender"]["data"]["type"]).to eq("member")
        expect(relationships).to include("recipient")
        expect(relationships["recipient"]["data"]["type"]).to eq("member")
        expect(relationships).to include("family")
      end
    end
  end
  context "Unauthorized Family Members" do
    before do
      @family_member = FactoryBot.create(:family_member)
      @other_family_member = FactoryBot.create(:family_member)
      login_auth(@other_family_member.member)
    end
    describe "POST /invites Invites#create for new members" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @other_family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
      end
      it "users can invite new members" do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe "POST /invites Invites#create for existing member accounts" do
      before(:each) do
        @other_second_family_member = FactoryBot.create(:family_member)
        @auth_headers = @member.create_new_auth_token
        @create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @other_family_member.member_id, recipient_id: @other_second_family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
      end
      it "users can invite new members" do
        @family_member.update_attributes(user_role: "owner")
        post "/v1/invites", params: {invite: @create_invite}, headers: @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end
  context "Unknown User" do
    before do
      @family_member = FactoryBot.create(:family_member)
      @other_family_member = FactoryBot.create(:family_member)
    end
    describe "POST /invites Invites#create for new members" do
      it "nil user is rejected" do
        create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
        post "/v1/invites", params: {invite: create_invite}
        expect(response).to have_http_status(401)
      end
    end
    describe "POST /invites Invites#create for existing member accounts" do
      it "nil user is rejected" do
        create_invite = FactoryBot.build(:invite, family_id: @family_member.family_id, sender_id: @family_member.member_id, recipient_id: @other_family_member.member_id).serializable_hash.except!("id", "token", "created_at", "updated_at", "accepted_at")
        post "/v1/invites", params: {invite: create_invite}
        expect(response).to have_http_status(401)
      end
    end
  end
  
end
