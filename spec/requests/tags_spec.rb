require 'rails_helper'

RSpec.describe "Tags", type: :request do
  context 'Known User' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now, user_role: "user")
      @member = family_member.member
      login_auth(@member)
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
    end
    describe 'GET /tags Tag#index' do
      it "gets a 200 status" do
        FactoryBot.create_list(:tag, 3)
        get "/v1/tags", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
    end
    describe 'POST /tags Tag#create' do
      it "gets a 200 status" do
        @tag_params = FactoryBot.build(:tag).as_json.except!("updated_at", "created_at", "id")
        post "/v1/tags", :params => {:tag => @tag_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
    end
    describe 'DELETE /tags Tag#destroy' do
      before do
        @tag_params = FactoryBot.create(:tag).as_json.except!("title", "description", "mature", "updated_at", "created_at")
      end
      it "gets a 403 status" do
        delete "/v1/tags/#{@tag_params["id"]}", :params => {:tag => @tag_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context ':: Admin' do
      before do
        FamilyMember.where(member_id: @member.id, family_id: @family.id).first.update_attributes(user_role: "admin")
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      describe 'DELETE /tags Tag#destroy' do
        before do
          @tag_params = FactoryBot.create(:tag).as_json.except!("title", "description", "mature", "updated_at", "created_at")
        end
        it "gets a 204 status" do
          delete "/v1/tags/#{@tag_params["id"]}", :params => {:tag => @tag_params}, :headers => @auth_headers
          expect(response).to have_http_status(204)
        end
      end
    end
  end
  context 'Unknown User' do
    describe 'GET /tags Tag#index' do
      before do
        @member = nil
        FactoryBot.create_list(:tag, 3)
      end
      it "gets a 401 status" do
        get "/v1/tags"
        expect(response).to have_http_status(401)
      end
    end
    describe 'POST /tags Tag#create' do
      it "gets a 401 status" do
        @tag_params = FactoryBot.build(:tag).as_json.except!("updated_at", "created_at", "id")
        post "/v1/tags", :params => {:tag => @tag_params}
        expect(response).to have_http_status(401)
      end
    end
    describe 'DELETE /tags Tag#destroy' do
      before do
        @tag_params = FactoryBot.create(:tag).as_json.except!("title", "description", "mature", "updated_at", "created_at")
      end
      it "gets a 401 status" do
        delete "/v1/tags/#{@tag_params["id"]}", :params => {:tag => @tag_params}
        expect(response).to have_http_status(401)
      end
    end
  end
end
