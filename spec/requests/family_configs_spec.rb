require 'rails_helper'
# This request test covers activites that involve:
# - updating FamilyConfig configuration

RSpec.describe "FamilyConfigs :: ", type: :request do
  before do
    @other_family = FactoryBot.create(:family)
    @family = FactoryBot.create(:family)
    @other_family_config = FactoryBot.create(:family_config, family_id: @other_family.id)
    @family_config = FactoryBot.create(:family_config, family_id: @family.id)
    @family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now, user_role: "owner")
    
    @member = @family_member.member
  end

  describe "FamilyConfig#show :: " do
    before do
      login_auth(@member)
      @family_params = {
        family_config: {
          id: @family_config.id,
          family_id: @family_config.family_id
        }
      }
      @other_family_params = {
        family_config: {
          id: @other_family_config.id,
          family_id: @other_family_config.family_id
        }
      }
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
    end
    it "allows to view FamilyConfigs where user_role is owner" do
      get "/v1/family_configs/#{@family_config.id}", :params => @family_params,:headers => @auth_headers
      json = JSON.parse(response.body)
      expect(response).to have_http_status(200)
    end
    it "forbids to view FamilyConfigs where user_role is not owner" do
      get "/v1/family_configs/#{@other_family_config.id}", :params => @other_family_params, :headers => @auth_headers
      expect(response).to have_http_status(403)
    end
  end

  describe "Owner can update :: " do
    before do
      login_auth(@member)
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
    end
    it "Owner can change authorization_enabled to: true => false" do
      params = {
        family_config: {
          id: @family_config.id,
          family_id: @family_config.family_id,
          authorization_enabled: "false"
        }
      }
      patch "/v1/family_configs/#{@family_config.id}", :params => params, :headers => @auth_headers
      expect(response).to have_http_status(200)
    end
    it "Owner can change authorization_enabled to: false => true" do
      params = {
        family_config: {
          id: @family_config.id,
          family_id: @family_config.family_id,
          authorization_enabled: "true"
        }
      }
      patch "/v1/family_configs/#{@family_config.id}", :params => params, :headers => @auth_headers
      expect(response).to have_http_status(200)
    end
  end

  describe "Owner can not update other family_configs :: " do
    before do
      login_auth(@member)
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
    end
    it "Owner can't change family_id to: true => false" do
      params = {
        family_config: {
          id: @other_family_config.id,
          family_id: @other_family_config.family_id,
          authorization_enabled: "true"
        }
      }
      patch "/v1/family_configs/#{@other_family_config.id}", :params => params, :headers => @auth_headers
      expect(response).to have_http_status(403)
    end
  end
end
