require 'rails_helper'
RSpec.describe "Reaction API", type: :request do
  before do
    @family = FactoryBot.create(:family)
    family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
    @member = family_member.member
    @member_family_id = @family.id
  end
  describe ':: Members / Same Family ::' do
    before do
      @subject = FactoryBot.create(:post, family_id: @member_family_id, member_id: @member.id)
      @subject_class = @subject.class.to_s.pluralize.downcase
      login_auth(@member)
    end
    context "GET subject/:id/reactions Reactions#index" do
      before do
        # bypass FactoryBot instantiation to create multiple family members
        5.times { FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member_id) }
        @comparable = Reaction.where(interaction_type: @subject.class.to_s, interaction_id: @subject.id).order('id DESC')
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 200 status" do
        get "/v1/#{@subject_class}/#{@subject.id}/reactions", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and can get all of the records available to the Member\'s policy via index' do
        get "/v1/#{@subject_class}/#{@subject.id}/reactions", :headers => @auth_headers
        json = JSON.parse(response.body) 
        expected_ids = @comparable.pluck(:id)
        actual = json["data"]
        actual.each do | i |
          expect(expected_ids).to include(i["id"].to_i)
        end
        expect(response).to have_http_status(200)
      end
      it 'and getting the index returns the count and matches the expectation' do
        get "/v1/#{@subject_class}/#{@subject.id}/reactions", :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable
        actual = json["data"]
        expect(actual.count).to eq(expected.count)
      end
      it 'and getting the index returns the interaction record and match' do
        get "/v1/#{@subject_class}/#{@subject.id}/reactions", :headers => @auth_headers
        expected = @comparable.pluck(:id)
        JSON.parse(response.body)["data"].each do |data| 
          expect(data["type"]).to eq("reaction")
          expect(expected).to include(data["id"].to_i)
        end
      end
      it 'shows relevant resources' do
        get "/v1/#{@subject_class}/#{@subject.id}/reactions", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"].first["relationships"]
        expect(actual).to include("interaction")
        expect(actual).to include("member")
      end
    end
    context "POST subjects/:id/reactions Reactions#create" do
      before do
       @comparable = FactoryBot.build(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @member.id)
       @create_request_params = {
            "attributes": {
              "emotive": @comparable.emotive,
              "interaction_type": @comparable.interaction_type,
              "interaction_id": @comparable.interaction_id,
              "member_id": @comparable.member_id
            }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status for principle route" do
        post "/v1/reactions", :params => {:reaction => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and it returns the json for the newly created reaction' do
        post '/v1/reactions', :params => {:reaction => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        comparable_id = Reaction.where(interaction_type: @comparable.interaction_type, interaction_id: @comparable.interaction_id, member_id: @comparable.member_id, emotive: @comparable.emotive).first.id
        expect(json["data"]["id"].to_i).to eq(comparable_id)
        expect(actual["emotive"]).to eq(@comparable.emotive)
        expect(actual["interaction-type"]).to eq(@comparable.interaction_type)
        expect(actual["interaction-id"]).to eq(@comparable.interaction_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)
      end
      it 'shows the relationships and links to them in the json package' do
        post '/v1/reactions', :params => {:reaction => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("interaction")
        expect(actual).to include("member")

        expect(actual["interaction"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["interaction"]["data"]["type"]).to eq(@subject.class.to_s.downcase)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
      it "it deletes old reactions before creating a new one" do
        Reaction.delete_all
        FactoryBot.create(:reaction, member_id: @member.id, interaction_type: @comparable.interaction_type, interaction_id: @comparable.interaction_id)
        post "/v1/reactions", :params => {:reaction => @create_request_params}, :headers => @auth_headers
        expect(Reaction.count).to eq(1)
      end
    end
    context "DELETE /reactions/:id Reactions#destroy" do
      before(:each) do
        @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @member.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a reaction" do
        delete_request_params = {:id => @comparable.id }
        delete "/v1/reactions/#{@comparable.id}", :params => {reaction: delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it 'returns 404 for missing content' do
        deleted_comparable_id = @comparable.id
        delete_request_params = {:id => deleted_comparable_id }
        Reaction.find(deleted_comparable_id).destroy
        delete "/v1/reactions/#{deleted_comparable_id}", :params => {reaction: delete_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body) 
        expect(json).to eq({})
        expect(response).to have_http_status(404)
      end
    end
    context "Unauthorize Inside Family ::" do
      before do
        @second_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
      end
      context "POST /reactions Reactions#create :: Member 2 => Member 1" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "unable to create using another family member's id" do
          @comparable = FactoryBot.build(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @second_member.id)
          @create_request_params = {
              "attributes": {
                "emotive": @comparable.emotive,
                "interaction_type": @comparable.interaction_type,
                "interaction_id": @comparable.interaction_id,
                "member_id": @comparable.member_id
              }
          }
          post "/v1/reactions", :params => {:reaction => @create_request_params}, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "DELETE /reactions Reactions#delete :: Member 2 => Member 1" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "unable to delete on another family member's reaction" do
          @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @second_member.id)
          delete_request_params = {reaction: {:id => @comparable.id }}
          delete "/v1/reactions/#{@comparable.id}", :params => delete_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Admin Role ::' do
    before do
      @subjects = FactoryBot.create_list(:post, 5, family_id: @member_family_id, member_id: @member.id)
      @subject = @subjects.first
      @subject_class = @subject.class.to_s.pluralize.downcase

      family_member = FactoryBot.create(:family_member, family_id: @family.id, user_role: "admin", authorized_at: DateTime.now)
      @member = family_member.member # admin
      @member_family_id = @family.id
      @normal_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member # normal user
      login_auth(@member) # login admin
    end
    context "POST /reactions Reactions#create :: Member 2 => Member 1" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "unable to create using another family member's id" do
        @comparable = FactoryBot.build(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @normal_member.id)
        @create_request_params = {
            "attributes": {
              "emotive": @comparable.emotive,
              "interaction_type": @comparable.interaction_type,
              "interaction_id": @comparable.interaction_id,
              "member_id": @comparable.member_id
            }
        }
        post "/v1/reactions", :params => {:reaction => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "DELETE /reactions Reactions#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a reaction" do
        @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @normal_member.id)
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/reactions/#{@comparable.id}", :params => {reaction: @delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
    end
  end # Members / Same Family - Admin Role Describe
  
  describe ':: Members / Unauthorized to Family ::' do
    before do
      logout_auth(@member)
      authorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @authorized_member_family_id = authorized_member.family_id
      @authorized_member = authorized_member.member
      @subject = FactoryBot.create(:post, family_id: @authorized_member_family_id, member_id: @authorized_member.id)

      unauthorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @unauthorized_member_family_id = unauthorized_member.family_id
      @unauthorized_member = unauthorized_member.member

      @join_member = FactoryBot.create(:member)
      FactoryBot.create(:family_member, member_id: @join_member.id, family_id: @authorized_member_family_id, authorized_at: DateTime.now)
      FactoryBot.create(:family_member, member_id: @join_member.id, family_id: @unauthorized_member_family_id, authorized_at: DateTime.now)
    end
    context "GET /reactions Reactions#index" do
      # This only applys to Recipes as interaction because each recipe belongs to a member.
      # Hypothetically, you could have one user (family A and B) who is apart of two families where the
      # third user (member of family B) is unable to see first user's reaction (family A).
      before do
        @index_subject = FactoryBot.create(:recipe, member_id: @join_member.id)
        @authorized_comparable = FactoryBot.create(:reaction, interaction_type: @index_subject.class.to_s, interaction_id: @index_subject.id, member_id: @authorized_member.id)
        @unauthorized_comparable = FactoryBot.create(:reaction, interaction_type: @index_subject.class.to_s, interaction_id: @index_subject.id, member_id: @unauthorized_member.id)
      end
      after(:each) do
        logout_auth(@member)
      end
      it "200 with nested subject and returns 1 reactions for unauthorized_member" do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/reactions/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(@unauthorized_comparable.id).to eq(actual.first["id"].to_i)
        expect(@authorized_comparable.id).to_not eq(actual.first["id"].to_i)
        expect(actual.count).to eq(1)
        expect(response).to have_http_status(200)
      end
      it "200 with nested subject and returns 1 reaction for authorized_member" do
        login_auth(@authorized_member) # @member = @authorized_member
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/reactions/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(@authorized_comparable.id).to eq(actual.first["id"].to_i)
        expect(@unauthorized_comparable.id).to_not eq(actual.first["id"].to_i)
        expect(actual.count).to eq(1)
        expect(response).to have_http_status(200)
      end
      it "200 with nested subject and returns 2 reactions for join_member" do
        login_auth(@join_member) # @member = @join_member
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/reactions/", :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body) 
        expect(json["data"].count).to eq(2)
        expected = [@authorized_comparable.id, @unauthorized_comparable.id]
        json["data"].each do |data| 
          expect(data["type"]).to eq("reaction")
          expect(expected).to include(data["id"].to_i)
        end
      end
    end
    context "POST /reactions Reactions#create" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.build(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @member.id)
        @create_request_params = {
          "reaction": {
            "attributes": {
              "emotive": @comparable.emotive,
              "interaction_type": @comparable.interaction_type,
              "interaction_id": @comparable.interaction_id,
              "member_id": @comparable.member_id
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "unable to create a reaction in another family" do
        post "/v1/reactions", :params => @create_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "DELETE /reactions Reactions#destroy" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized attempt to delete" do
        @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @authorized_member.id)
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/reactions/#{@comparable.id}", :params => {reaction: @delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Unauthorized to Family Describe
  describe ':: Unknown User ::' do
    before do
      logout_auth(@member)
      authorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @authorized_member_family_id = authorized_member.family_id
      @authorized_member = authorized_member.member
      @subject = FactoryBot.create(:post, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
      @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @authorized_member.id)
    end
    context "GET /reactions Reactions#index" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/#{@subject.class.to_s.downcase.pluralize}/#{@subject.id}/reactions"
        expect(response).to have_http_status(401)
      end
    end
    context "POST /reactions Reactions#create" do
      it "returns a 401 error saying they are not authenticated" do
        comparable_for_create = FactoryBot.build(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: nil)
        @create_request_params = {
          "reaction": {
            "attributes": {
              "emotive": @comparable.emotive,
              "interaction_type": comparable_for_create.interaction_type,
              "interaction_id": comparable_for_create.interaction_id,
              "member_id": comparable_for_create.member_id
            }
          }
        }
        post "/v1/reactions", :params => @comparable_for_create
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /reactions Reactions#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        @comparable = FactoryBot.create(:reaction, interaction_type: @subject.class.to_s, interaction_id: @subject.id, member_id: @authorized_member.id )
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/reactions/#{@comparable.id}", :params => @delete_request_params
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe


end
