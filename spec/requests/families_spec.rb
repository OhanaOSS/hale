require 'rails_helper'

RSpec.describe "Families", type: :request do
  describe ':: Members / Same Family ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @member = family_member.member
      login_auth(@member)
    end
    context "GET /families Family#index" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status and matches schema" do
        get '/v1/families', :headers => @auth_headers
        actual = JSON.parse(response.body)["data"].first
        expect(response).to have_http_status(200)
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["attributes"]).to include("family-name")
        expect(actual["links"]).to include("self")
      end
      it 'and can get all of the records available in the instance' do
        get '/v1/families'
        actual = JSON.parse(response.body)["data"].count
        expected = Family.count
        expect(response).to have_http_status(200)
        expect(actual).to eq(expected)
      end
    end
    context "GET /families/:id Family#show" do
      before do
        FactoryBot.create_list(:family_member, 5, family_id: @family.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status and matches schema" do
        get "/v1/families/#{@family.id}", :headers => @auth_headers
        actual = JSON.parse(response.body)["data"].first
        expect(response).to have_http_status(200)
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["attributes"]).to include("name")
        expect(actual["attributes"]).to include("surname")
        expect(actual["attributes"]).to include("nickname")
        expect(actual["attributes"]).to include("avatar")
        expect(actual["relationships"]["families"]["data"].first).to include("id")
        expect(actual["relationships"]["families"]["data"].first).to include("type")
        expect(actual["relationships"]["families"]["links"]).to include("related")
        expect(actual["links"]).to include("self")
      end
      it 'and can get all of the member records available in the family' do
        get "/v1/families/#{@family.id}", :headers => @auth_headers
        actual = JSON.parse(response.body)["data"].count
        expected = FamilyMember.where(family_id: @family.id).count
        expect(response).to have_http_status(200)
        expect(actual).to eq(expected)
      end
    end
    context "PUT-PATCH /families/:id Family#update" do
      before do
        update = FactoryBot.build(:family)
        @update_params = {
          "id": @family.id,
          "family": {
            "id": @family.id,
            "attributes": {
              "family_name": update.family_name
            }
          }
        }
      end
      context "Users" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
    context "DELETE /families/:id Family#destroy" do
      before do
        update = FactoryBot.build(:family)
        @delete_params = {
          "family": {
            "id": @family.id
          }
        }
      end
      context "Users" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
    context "POST /families Family#invite_to" do
      before do
        @invite_emails = "#{Faker::Internet.email}, #{Faker::Internet.email}"
        @mass_invite_params = {
          "id": @family.id,
          "family": {
            "id": @family.id,
            "invite_emails": @invite_emails
          }
        }
      end
      context "User" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          response_message = JSON.parse(response.body)["data"]["message"]
          expect(response_message).to include(@invite_emails)
          expect(response).to have_http_status(200)
        end
        it "should increase invite count" do
          Invite.delete_all
          expect(Invite.count).to eq(0)
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(200)
          expect(Invite.count).to eq(@invite_emails.split(', ').count)
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Owner Role ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, user_role: "owner")
      @member = family_member.member
      login_auth(@member)
    end
    context "PUT-PATCH /families/:id Family#update" do
      before(:each) do
        update = FactoryBot.build(:family)
        @update_params = {
          "id": @family.id,
          "family": {
            "id": @family.id,
            "attributes": {
              "family_name": update.family_name
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "should be authorized for updates #put" do
        put "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["id"].to_i).to eq(@family.id)
        expect(actual["attributes"]["family-name"]).to_not eq(@family.family_name)
        expect(actual["attributes"]["family-name"]).to eq(@update_params[:family][:attributes][:family_name])
        expect(actual["attributes"]).to include("family-name")
        expect(actual["links"]).to include("self")
        expect(response).to have_http_status(200)
      end
      it "should be authorized for updates #patch" do
        patch "/v1/families/#{@family.id}", :params => @update_params, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["id"].to_i).to eq(@family.id)
        expect(actual["attributes"]["family-name"]).to_not eq(@family.family_name)
        expect(actual["attributes"]["family-name"]).to eq(@update_params[:family][:attributes][:family_name])
        expect(actual["attributes"]).to include("family-name")
        expect(actual["links"]).to include("self")
        expect(response).to have_http_status(200)
      end
    end
    context "DELETE /families/:id Family#destroy" do
      before do
        update = FactoryBot.build(:family)
        @delete_params = {
          "family": {
            "id": @family.id
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "should be authorized for delete" do
        delete "/v1/families/#{@family.id}", :params => @delete_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
        expect(FamilyConfig.where(family_id: @family.id)).to eq([])
      end
    end
    context "POST /families Family#invite_to" do
      before do
        @invite_emails = "#{Faker::Internet.email}, #{Faker::Internet.email}"
        @mass_invite_params = {
          "id": @family.id,
          "family": {
            "id": @family.id,
            "invite_emails": @invite_emails
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "should be authorized for mass invites" do
        post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
        response_message = JSON.parse(response.body)["data"]["message"]
        expect(response_message).to include(@invite_emails)
        expect(response).to have_http_status(200)
      end
      it "should increase invite count" do
        Invite.delete_all
        expect(Invite.count).to eq(0)
        post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
        expect(Invite.count).to eq(@invite_emails.split(', ').count)
      end
    end
  end # Members / Same Family - Admin Role Describe
  
  describe ':: Members / Outside of Family ::' do
    before do
      @other_family = FactoryBot.create(:family)
      @non_family_member = FactoryBot.create(:family_member, family_id: @other_family.id).member
      @family = FactoryBot.create(:family)
      @member = FactoryBot.create(:family_member, family_id: @family.id).member
    end
    context "GET /families Family#index" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status and matches schema" do
        get '/v1/families', :headers => @auth_headers
        actual = JSON.parse(response.body)["data"].first
        expect(response).to have_http_status(200)
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["attributes"]).to include("family-name")
        expect(actual["links"]).to include("self")
      end
      it 'and can get all of the records available in the instance' do
        get '/v1/families'
        actual = JSON.parse(response.body)["data"].count
        expected = Family.count
        expect(response).to have_http_status(200)
        expect(actual).to eq(expected)
      end
    end
    context "GET /families/:id Family#show" do
      before do
        FactoryBot.create_list(:family_member, 5, family_id: @other_family.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "and can't get member records for other family" do
        get "/v1/families/#{@other_family.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "PUT-PATCH /families/:id Family#update" do
      before do
        update = FactoryBot.build(:family)
        @update_params = {
          "id": @other_family.id,
          "family": {
            "id": @other_family.id,
            "attributes": {
              "family_name": update.family_name
            }
          }
        }
      end
      context "Users" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Owner" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for updates #put" do
          put "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not be authorized for updates #patch" do
          patch "/v1/families/#{@other_family.id}", :params => @update_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
    context "DELETE /families/:id Family#destroy" do
      before do
        update = FactoryBot.build(:family)
        @delete_params = {
          "family": {
            "id": @other_family.id
          }
        }
      end
      context "Users" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@other_family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@other_family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@other_family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "Owner" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for delete" do
          delete "/v1/families/#{@other_family.id}", :params => @delete_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
    context "POST /families Family#invite_to" do
      before do
        @invite_emails = "#{Faker::Internet.email}, #{Faker::Internet.email}"
        @mass_invite_params = {
          "id": @other_family.id,
          "family": {
            "id": @other_family.id,
            "invite_emails": @invite_emails
          }
        }
      end
      context "User" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "user")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
      context "Moderator" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
      context "Admin" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "admin")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
      context "Owner" do
        before do
          FamilyMember.where(family_id: @family.id, member_id: @member.id).first.update_attributes(user_role: "moderator")
        end
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "should not be authorized for mass invites" do
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "should not increase invite count" do
          Invite.delete_all
          post "/v1/families", :params => @mass_invite_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(Invite.count).to eq(0)
        end
      end
    end

  end # Members / Unauthorized to Family Describe
  
  describe ':: Unknown User ::' do
    before do
      @family = FactoryBot.create(:family)
      @member = nil
    end
    context "GET /families Family#index" do
      it "200 status and matches schema" do
        get '/v1/families'
        actual = JSON.parse(response.body)["data"].first
        expect(response).to have_http_status(200)
        expect(actual).to include("type")
        expect(actual).to include("id")
        expect(actual["attributes"]).to include("family-name")
        expect(actual["links"]).to include("self")
      end
      it 'and can get all of the records available in the instance' do
        get '/v1/families'
        actual = JSON.parse(response.body)["data"].count
        expected = Family.count
        expect(response).to have_http_status(200)
        expect(actual).to eq(expected)
      end
    end
    context "GET /families/:id Family#show" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/families/#{@family.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "PUT-PATCH /families Family#update" do
      it "#put returns a 401 error saying they are not authenticated" do
        put "/v1/families/#{@family.id}"
        expect(response).to have_http_status(401)
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        patch "/v1/families/#{@family.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /families Family#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        delete "/v1/families/#{@family.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "POST /families Family#invite_to" do
      it "returns a 401 error saying they are not authenticated" do
        post "/v1/families"
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe
end
