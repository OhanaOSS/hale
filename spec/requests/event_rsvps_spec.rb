require 'rails_helper'
# RSVPs are viewed as an include to an Event.
RSpec.describe "EventRsvps", type: :request do
  before do
    @family = FactoryBot.create(:family)
    family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
    subject_family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
    @member = family_member.member
    @member_family_id = family_member.family_id
    @subject = FactoryBot.create(:event, family_id: @family.id, member_id: subject_family_member.id)
  end
  describe ':: Members / Same Family ::' do
    before do
      login_auth(@member)
    end
    describe "POST /event_rsvps EventRsvps#create" do
      before do
        recipe = FactoryBot.create(:recipe, member_id: @member.id)
        @comparable = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: recipe.id, non_recipe_description: nil, serving: 5, member_id: @member.id, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        @create_request_params_with_food = {
          "event_rsvp":{
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>@comparable.bringing_food,
              "recipe_id"=>@comparable.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>@comparable.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
        @create_request_params_without_food = {
          "event_rsvp":{
            "attributes": {
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status and matches schema without food" do
        expected = @create_request_params_without_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_without_food, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json).to include("id")
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(expected["party_size"])
        expect(actual["rsvp"]).to eq(expected["rsvp"])
        expect(actual["bringing-food"]).to eq(false)
        expect(actual["recipe-id"]).to eq(nil)
        expect(actual["non-recipe-description"]).to eq(nil)
        expect(actual["serving"]).to eq(0)
        expect(actual["member-id"]).to eq(expected["member_id"])
        expect(actual["party-companions"]).to eq(expected["party_companions"])
        expect(actual["event-id"]).to eq(expected["event_id"])
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
      it "200 status and matches schema with food" do
        expected = @create_request_params_with_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_with_food, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json).to include("id")
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(expected["party_size"])
        expect(actual["rsvp"]).to eq(expected["rsvp"])
        expect(actual["bringing-food"]).to eq(expected["bringing_food"])
        expect(actual["recipe-id"]).to eq(expected["recipe_id"])
        expect(actual["non-recipe-description"]).to eq(expected["non_recipe_description"])
        expect(actual["serving"]).to eq(expected["serving"])
        expect(actual["member-id"]).to eq(expected["member_id"])
        expect(actual["party-companions"]).to eq(expected["party_companions"])
        expect(actual["event-id"]).to eq(expected["event_id"])
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
      it "show relationships" do
        expected = @create_request_params_with_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_with_food, :headers => @auth_headers
        event_id = JSON.parse(response.body)["data"]['attributes']["event-id"].to_i
        member_id = JSON.parse(response.body)["data"]['attributes']["member-id"].to_i
        actual = JSON.parse(response.body)["data"]["relationships"]

        expect(response).to have_http_status(200)
        expect(actual).to include("event")
        expect(actual["event"]["data"]).to include("id")
        expect(actual["event"]["data"]["id"].to_i).to eq(event_id)
        expect(actual["event"]["data"]).to include("type")
        expect(actual["event"]["links"]).to include("related")
        expect(actual["event"]["links"]["related"]).to eq("/v1/events/#{event_id}")

        expect(actual["member"]["data"]).to include("id")
        expect(actual["member"]["data"]["id"].to_i).to eq(member_id)
        expect(actual["member"]["data"]).to include("type")
        expect(actual["member"]["links"]).to include("related")
        expect(actual["member"]["links"]["related"]).to eq("/v1/members/#{member_id}")
      end
      it 'returns a conflict error when duplicate rsvps are found' do
        conflict_comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: nil, non_recipe_description: "foobar james", serving: 5, member_id: @member.id, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        post '/v1/events_rsvps', :params => {event_rsvp: {attributes: conflict_comparable.as_json }}, :headers => @auth_headers
        error = JSON.parse(response.body)["errors"].first
        expect(response).to have_http_status(:conflict)
        expect(error).to eq("Id Conflicting RSVP, please send PUT/PATCH to update event_rsvp id: #{conflict_comparable.id}")
      end
    end
    describe 'PUT-PATCH /event_rsvps/:id EventRsvps#update' do
      before do
        recipe = FactoryBot.create(:recipe, member_id: @member.id)
        @comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: recipe.id, non_recipe_description: nil, serving: 5, member_id: @member.id, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        update = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: @member.id, party_companions: @comparable.party_companions, event_id: @subject.id)
        @update_put_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>update.bringing_food,
              "recipe_id"=>update.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>update.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
        @update_patch_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 200 status and matches updates" do
        expected = @update_put_params[:event_rsvp][:attributes].as_json
        put "/v1/events_rsvps/#{@comparable.id}", :params => @update_put_params, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json["id"].to_i).to eq(@comparable.id)
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(expected["party_size"])
        expect(actual["rsvp"]).to eq(expected["rsvp"])
        expect(actual["bringing-food"]).to eq(expected["bringing_food"])
        expect(actual["recipe-id"]).to eq(expected["recipe_id"])
        expect(actual["non-recipe-description"]).to eq(expected["non_recipe_description"])
        expect(actual["serving"]).to eq(expected["serving"])
        expect(actual["member-id"]).to eq(expected["member_id"])
        expect(actual["party-companions"]).to eq(expected["party_companions"])
        expect(actual["event-id"]).to eq(expected["event_id"])
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
      it "#put 200 status and matches updates" do
        expected = @update_patch_params[:event_rsvp][:attributes].as_json
        patch "/v1/events_rsvps/#{@comparable.id}", :params => @update_patch_params, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json["id"].to_i).to eq(@comparable.id)
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(@comparable.party_size)
        expect(actual["rsvp"]).to eq(@comparable.rsvp)
        expect(actual["bringing-food"]).to eq(@comparable.bringing_food)
        expect(actual["recipe-id"]).to eq(@comparable.recipe_id)
        expect(actual["non-recipe-description"]).to eq(@comparable.non_recipe_description)
        expect(actual["serving"]).to eq(@comparable.serving)
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["party-companions"]).to eq(@comparable.party_companions)
        expect(actual["event-id"]).to eq(@comparable.event_id)
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
    end
    describe 'DELETE /event_rsvps/:id EventRsvps#destroy' do
      before(:each) do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 1, rsvp: "yes", member_id: @member.id, party_companions: [], event_id: @subject.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "204 status on sucess" do
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it "404 status on record not found" do
        EventRsvp.find(@comparable.id).delete
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(404)
      end
    end
  end # Members / Same Family
  describe ':: Members / Same Family (Other Users) ::' do
    before do
      login_auth(@member)
    end
    describe "POST /event_rsvps EventRsvps#create" do
      before do
        @comparable = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        @create_request_params_without_food = {
          "event_rsvp":{
            "attributes": {
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "403 status to create" do
        expected = @create_request_params_without_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_without_food, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe 'PUT-PATCH /event_rsvps/:id EventRsvps#update' do
      before do
        recipe = FactoryBot.create(:recipe, member_id: @member.id)
        @comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: recipe.id, non_recipe_description: nil, serving: 5, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        update = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: @member.id, party_companions: @comparable.party_companions, event_id: @subject.id)
        @update_put_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>update.bringing_food,
              "recipe_id"=>update.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>update.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
        @update_patch_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 200 status and matches updates" do
        expected = @update_put_params[:event_rsvp][:attributes].as_json
        put "/v1/events_rsvps/#{@comparable.id}", :params => @update_put_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it "#put 200 status and matches updates" do
        expected = @update_patch_params[:event_rsvp][:attributes].as_json
        patch "/v1/events_rsvps/#{@comparable.id}", :params => @update_patch_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe 'DELETE /event_rsvps/:id EventRsvps#destroy' do
      before(:each) do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 1, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [], event_id: @subject.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "204 status on sucess" do
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Same Family (Other Users)
  describe ':: Members / Same Family (Admin) ::' do
    before do
      FamilyMember.where(member_id: @member.id, family_id: @member_family_id).first.update_attributes(user_role: "admin")
      login_auth(@member)
    end
    describe "POST /event_rsvps EventRsvps#create" do
      before do
        @comparable = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        @create_request_params_without_food = {
          "event_rsvp":{
            "attributes": {
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "403 status to create" do
        expected = @create_request_params_without_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_without_food, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe 'PUT-PATCH /event_rsvps/:id EventRsvps#update' do
      before do
        recipe = FactoryBot.create(:recipe, member_id: @member.id)
        @comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: recipe.id, non_recipe_description: nil, serving: 5, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        update = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: @member.id, party_companions: @comparable.party_companions, event_id: @subject.id)
        @update_put_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>update.bringing_food,
              "recipe_id"=>update.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>update.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
        @update_patch_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 200 status and matches updates" do
        expected = @update_put_params[:event_rsvp][:attributes].as_json
        put "/v1/events_rsvps/#{@comparable.id}", :params => @update_put_params, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json["id"].to_i).to eq(@comparable.id)
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(expected["party_size"])
        expect(actual["rsvp"]).to eq(expected["rsvp"])
        expect(actual["bringing-food"]).to eq(expected["bringing_food"])
        expect(actual["recipe-id"]).to eq(expected["recipe_id"])
        expect(actual["non-recipe-description"]).to eq(expected["non_recipe_description"])
        expect(actual["serving"]).to eq(expected["serving"])
        expect(actual["member-id"]).to eq(expected["member_id"])
        expect(actual["party-companions"]).to eq(expected["party_companions"])
        expect(actual["event-id"]).to eq(expected["event_id"])
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
      it "#put 200 status and matches updates" do
        expected = @update_patch_params[:event_rsvp][:attributes].as_json
        patch "/v1/events_rsvps/#{@comparable.id}", :params => @update_patch_params, :headers => @auth_headers
        json = JSON.parse(response.body)['data']
        actual = json['attributes']
        expect(response).to have_http_status(200)
        expect(json["id"].to_i).to eq(@comparable.id)
        expect(json["type"]).to eq("event-rsvp")
        expect(actual["party-size"]).to eq(@comparable.party_size)
        expect(actual["rsvp"]).to eq(@comparable.rsvp)
        expect(actual["bringing-food"]).to eq(@comparable.bringing_food)
        expect(actual["recipe-id"]).to eq(@comparable.recipe_id)
        expect(actual["non-recipe-description"]).to eq(@comparable.non_recipe_description)
        expect(actual["serving"]).to eq(@comparable.serving)
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["party-companions"]).to eq(@comparable.party_companions)
        expect(actual["event-id"]).to eq(@comparable.event_id)
        expect(actual["rsvp-note"]).to eq(expected["rsvp_note"])
      end
    end
    describe 'DELETE /event_rsvps/:id EventRsvps#destroy' do
      before(:each) do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 1, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [], event_id: @subject.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "204 status on sucess" do
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it "404 status on record not found" do
        EventRsvp.find(@comparable.id).delete
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(404)
      end
    end
  end # Members / Same Family (Admin)
  describe ':: Members / Other Family ::' do
    before do
      logout_auth(@member)
      @member = FactoryBot.create(:family_member, authorized_at: DateTime.now).member
      login_auth(@member)
    end
    describe "POST /event_rsvps EventRsvps#create" do
      before do
        @comparable = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        @create_request_params_without_food = {
          "event_rsvp":{
            "attributes": {
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "403 status to create" do
        expected = @create_request_params_without_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_without_food, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe 'PUT-PATCH /event_rsvps/:id EventRsvps#update' do
      before do
        recipe = FactoryBot.create(:recipe, member_id: @member.id)
        @comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: recipe.id, non_recipe_description: nil, serving: 5, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        update = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: @member.id, party_companions: @comparable.party_companions, event_id: @subject.id)
        @update_put_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>update.bringing_food,
              "recipe_id"=>update.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>update.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
        @update_patch_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 200 status and matches updates" do
        expected = @update_put_params[:event_rsvp][:attributes].as_json
        put "/v1/events_rsvps/#{@comparable.id}", :params => @update_put_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it "#put 200 status and matches updates" do
        expected = @update_patch_params[:event_rsvp][:attributes].as_json
        patch "/v1/events_rsvps/#{@comparable.id}", :params => @update_patch_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    describe 'DELETE /event_rsvps/:id EventRsvps#destroy' do
      before(:each) do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 1, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [], event_id: @subject.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "204 status on sucess" do
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Other Family
  describe ':: Unkown User ::' do
    before do
      logout_auth(@member)
      @member = nil
    end
    describe "POST /event_rsvps EventRsvps#create" do
      before do
        @comparable = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        @create_request_params_without_food = {
          "event_rsvp":{
            "attributes": {
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>@comparable.rsvp_note
            }
          }
        }
      end
      it "403 status to create" do
        expected = @create_request_params_without_food[:event_rsvp][:attributes].as_json
        post '/v1/events_rsvps', :params => @create_request_params_without_food
        expect(response).to have_http_status(401)
      end
    end
    describe 'PUT-PATCH /event_rsvps/:id EventRsvps#update' do
      before do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: true, recipe_id: nil, non_recipe_description: nil, serving: 5, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], event_id: @subject.id)
        update = FactoryBot.build(:event_rsvp, party_size: 2, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i], party_companions: @comparable.party_companions, event_id: @subject.id)
        @update_put_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "party_size"=>@comparable.party_size,
              "rsvp"=>@comparable.rsvp,
              "bringing_food"=>update.bringing_food,
              "recipe_id"=>update.recipe_id,
              "non_recipe_description"=>nil,
              "serving"=>update.serving,
              "member_id"=>@comparable.member_id,
              "party_companions"=>@comparable.party_companions,
              "event_id"=>@comparable.event_id,
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
        @update_patch_params = {
          "event_rsvp":{
            "id": @comparable.id,
            "attributes": { 
              "rsvp_note"=>update.rsvp_note
            }
          }
        }
      end
      it "#put 200 status and matches updates" do
        expected = @update_put_params[:event_rsvp][:attributes].as_json
        put "/v1/events_rsvps/#{@comparable.id}", :params => @update_put_params
        expect(response).to have_http_status(401)
      end
      it "#put 200 status and matches updates" do
        expected = @update_patch_params[:event_rsvp][:attributes].as_json
        patch "/v1/events_rsvps/#{@comparable.id}", :params => @update_patch_params
        expect(response).to have_http_status(401)
      end
    end
    describe 'DELETE /event_rsvps/:id EventRsvps#destroy' do
      before(:each) do
        @comparable = FactoryBot.create(:event_rsvp, party_size: 1, rsvp: "yes", member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member.id.to_i, party_companions: [], event_id: @subject.id)
      end
      it "204 status on sucess" do
        delete "/v1/events_rsvps/#{@comparable.id}", :params => {:event_rsvp => {id: @comparable.id}}
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User
end #Rspec.describe
