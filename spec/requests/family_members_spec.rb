require 'rails_helper'

RSpec.describe "FamilyMembers", type: :request do
  describe "Authorized and Authenticated" do
    before do
      @family = FactoryBot.create(:family)
      @comparables = FactoryBot.create_list(:family_member, 5, family_id: @family.id, user_role: "user")
      @comparables = @comparables.sort { |a,b| a.id <=> b.id }
    end
    context 'Family Owner' do
      before do
        @family_member = @comparables.last
        @family_member.update_attributes(user_role: "owner")
        @member = @family_member.member
        login_auth(@member)
        @comparable = @comparables.first
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "admin"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it '200 for index' do
        get "/v1/family_members/", :headers => @auth_headers
        actual_sorted = JSON.parse(response.body)["data"].sort { |a,b| a["id"] <=> b["id"] }
        expect(actual_sorted.count).to eq(@comparables.count)
        expect(actual_sorted.first["id"]).to eq(@comparables.first.id.to_s)
        expect(actual_sorted.first["attributes"]).to include("family-id")
        expect(actual_sorted.first["attributes"]).to include("member-id")
        expect(actual_sorted.first["attributes"]).to include("user-role")
        expect(response).to have_http_status(200)
      end
      it '200 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(actual.count).to eq(@comparables.count)
        expect(actual["id"]).to eq(@comparables.first.id.to_s)
        expect(actual["attributes"]).to include("family-id")
        expect(actual["attributes"]).to include("member-id")
        expect(actual["attributes"]["user-role"]).to eq("admin")
        expect(response).to have_http_status(200)
      end
      it '200 for update-patch' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it '200 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
    end
    context 'Family Admin' do
      before do
        @family_member = @comparables.last
        @family_member.update_attributes(user_role: "admin")
        @member = @family_member.member
        login_auth(@member)
        @comparable = @comparables.first
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "moderator"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it '200 for index' do
        get "/v1/family_members/", :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(actual.count).to eq(@comparables.count)
        expect(actual.first["id"]).to eq(@comparables.first.id.to_s)
        expect(actual.first["attributes"]).to include("family-id")
        expect(actual.first["attributes"]).to include("member-id")
        expect(actual.first["attributes"]).to include("user-role")
        expect(response).to have_http_status(200)
      end
      it '200 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(actual.count).to eq(@comparables.count)
        expect(actual["id"]).to eq(@comparables.first.id.to_s)
        expect(actual["attributes"]).to include("family-id")
        expect(actual["attributes"]).to include("member-id")
        expect(actual["attributes"]["user-role"]).to eq("moderator")
        expect(response).to have_http_status(200)
      end
      it '200 for update-patch' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it '200 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
    end
    context 'Family Admin - unauthorized' do
      before do
        @family_owner = @comparables.second
        @family_owner.update_attributes(user_role: "owner")
        @family_member = @comparables.last
        @family_member.update_attributes(user_role: "admin")
        @member = @family_member.member
        login_auth(@member)
        @comparable = @family_member
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "owner"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it 'admin can\'t make themself an owner update-patch' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it 'admin can\'t delete an owner update-patch' do
        delete "/v1/family_members/#{@family_owner.id}", :params => {:id => @family_owner.id}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end
  describe 'Unauthorized and Unauthenticated' do
    before do
      @family = FactoryBot.create(:family)
      @comparables = FactoryBot.create_list(:family_member, 5, family_id: @family.id, user_role: "user")
      @other_family = FactoryBot.create(:family)
      @other_owner = FactoryBot.create(:family_member, family_id: @other_family.id, user_role: "owner")
    end
    context 'Family Users' do
      before do
        @family_member = @comparables.last
        @member = @family_member.member
        login_auth(@member)
        @comparable = @comparables.first
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "owner"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it '403 for index' do
        get "/v1/family_members/", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for update-post' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context 'Family Moderators' do
      before do
        @family_member = @comparables.last
        @family_member.update_attributes(user_role: "moderator")
        @member = @family_member.member
        login_auth(@member)
        @comparable = @comparables.first
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "owner"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it '403 for index' do
        get "/v1/family_members/", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for update-post' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context 'Non-Family' do
      before do
        @family_member = @other_owner
        @member = @family_member.member
        @comparable = @comparables.first
        login_auth(@member)
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "owner"
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it '200 for index with scope' do
        get "/v1/family_members/", :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)["data"]
        actual = json.first
        expect(actual["id"].to_i).to eq(@other_owner.id)
        expect(json.count).to_not eq(FamilyMember.all.count)
      end
      it '403 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for update-post' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it '403 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context 'Nil Current_User' do
      before do
        @comparable = @comparables.first
        @member = nil
        @test_params = {
          family_member: {
            id: @comparable.id,
            user_role: "owner"
          }
        }
      end
      it '403 for index' do
        get "/v1/family_members/"
        expect(response).to have_http_status(401)
      end
      it '403 for update-put' do
        put "/v1/family_members/#{@comparable.id}", :params => @test_params
        expect(response).to have_http_status(401)
      end
      it '403 for update-post' do
        patch "/v1/family_members/#{@comparable.id}", :params => @test_params
        expect(response).to have_http_status(401)
      end
      it '403 for delete' do
        delete "/v1/family_members/#{@comparable.id}", :params => @test_params
        expect(response).to have_http_status(401)
      end
    end
  end
end
