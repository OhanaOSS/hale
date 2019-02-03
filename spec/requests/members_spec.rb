require 'rails_helper'
RSpec.describe "Member API", type: :request do
  before do
    @member_family_id  = FactoryBot.create(:family).id
    @alt_family_id = FactoryBot.create(:family).id

    family_member = FactoryBot.create(:family_member, family_id: @member_family_id, authorized_at: DateTime.now)
    @member = family_member.member
    FactoryBot.create_list(:family_member, 9, family_id: @member_family_id,  authorized_at: DateTime.now)
    FactoryBot.create_list(:family_member, 10, family_id: @alt_family_id,  authorized_at: DateTime.now)

    @provided_avatar_file = fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg')
    @provided_avatar_filename = 'img.jpg'
    @provided_avatar_content_type = 'avatar/jpg'

    @default_avatar_file = "assets/images/default_avatar.png"
  end
  describe ':: Members / Same Family ::' do
    before do
      login_auth(@member)
    end
    context "GET /members Members#index" do
      before do
        @comparable = FamilyMember.where(family_id: @member_family_id).where.not(authorized_at: nil)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 200 status" do
        get '/v1/members', :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "returns 200 status for Members#index alias" do
        get '/v1/directory', :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "acutal member count matches expected member count" do
        get '/v1/members', :headers => @auth_headers
        json = JSON.parse(response.body) 
        expected = @comparable.count
        actual = json["data"].count
        expect(actual).to eq(expected)
        expect(response).to have_http_status(200)
      end
      it 'scoped actual id\'s match the expected' do
        get '/v1/members', :headers => @auth_headers
        json = JSON.parse(response.body)

        alt_family_member_ids = FamilyMember.where(family_id: @alt_family_id).pluck(:member_id)
        member_family_member_ids = FamilyMember.where(family_id: @member_family_id).pluck(:member_id)

        json["data"].each do |record|
          expect(member_family_member_ids.include?(record["id"].to_i)).to eq(true)
          expect(alt_family_member_ids.include?(record["id"].to_i)).to eq(false)
          record["relationships"]["families"]["data"].each do |subrecord|
            expect(subrecord["id"].to_i).to eq(@member_family_id) if subrecord["type"] == "family"
          end
        end
        expect(response).to have_http_status(200)
      end
      it 'correct serialization for directory/index format for test record' do
        get '/v1/members', :headers => @auth_headers

        json = JSON.parse(response.body)
        actual = json["data"].first

        expect(actual).to include("id")
        expect(actual).to include("type")

        # Attributes
        expect(actual["attributes"]).to include("name")
        expect(actual["attributes"]).to include("surname")
        expect(actual["attributes"]).to include("nickname")
        expect(actual["attributes"]).to include("avatar")
        
        # Links
        expect(actual).to include("links")
        expect(actual["links"]).to include("self")
        expect(actual["links"]["self"]).to eq(api_v1_member_path(id: actual["id"]))

        # Relationships
        actual_relationships = actual["relationships"]
        expect(actual_relationships["families"]).to include("data")
        expect(actual_relationships["families"]).to include("links")

        # Relationship Data
        actual_relationship_data = actual_relationships["families"]["data"].first
        expect(actual_relationship_data).to include("id")
        expect(actual_relationship_data).to include("type")
        # Relationship Links
        actual_relationship_links = actual_relationships["families"]["links"]
        expect(actual_relationship_links).to include("related")
        expected_family_id = FamilyMember.where(member_id: actual["id"].to_i).pluck(:family_id).uniq.first
        expect(actual_relationship_links["related"]).to eq(api_v1_family_path(id: expected_family_id))
      end
    end
    context "GET /members/:id Members#show (non-current_user)" do
      before do
        @comparables = FamilyMember.where(family_id: @member_family_id).where.not(authorized_at: nil, member_id: @member.id)
        @comparable = @comparables.first.member
        @avatar_attached_comparable = @comparable
        @avatar_attached_comparable.avatar.attach(io: File.open(@provided_avatar_file), filename: @provided_avatar_filename, content_type: @provided_avatar_content_type)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "shows 200 status" do
        get "/v1/members/#{@comparable.id}", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'correct serialization for general profile/show format for test record' do
        # This has a authorized rendering as well including important user info.
        get "/v1/members/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]
        expected = @comparable
        expect(actual).to include("id")
        expect(actual).to include("type")

        # Attributes
        expect(actual["attributes"]).to include("name")
        expect(actual["attributes"]).to include("surname")
        expect(actual["attributes"]).to include("nickname")
        expect(actual["attributes"]).to include("avatar")
        

        expect(actual["attributes"]).to include("contacts")
        expect(actual["attributes"]).to include("addresses")
        expect(actual["attributes"]).to include("gender")
        expect(actual["attributes"]).to include("bio")
        expect(actual["attributes"]).to include("birthday")
        expect(actual["attributes"]).to include("instagram")


        # Links
        expect(actual).to include("links")
        expect(actual["links"]).to include("self")
        expect(actual["links"]["self"]).to eq(api_v1_member_path(id: actual["id"]))

        # Relationships
        actual_relationships = actual["relationships"]
        expect(actual_relationships["families"]).to include("data")
        expect(actual_relationships["families"]).to include("links")

        expect(actual_relationships).to include("event-rsvps")
        expect(actual_relationships).to include("family-members")
        expect(actual_relationships).to include("posts")
        expect(actual_relationships).to include("recipes")
      end
      it 'actual matches expected across test record' do
        # This has a authorized rendering as well including important user info.
        get "/v1/members/#{@comparable.id}", :headers => @auth_headers

        json = JSON.parse(response.body)
        actual = json["data"]
        expected = @comparable

        expect(actual["id"]).to eq(expected.id.to_s)
        expect(actual["type"]).to eq(expected.class.to_s.downcase)

        # Attributes
        expect(actual["attributes"]["name"]).to eq(expected.name)
        expect(actual["attributes"]["surname"]).to eq(expected.surname)
        expect(actual["attributes"]["nickname"]).to eq(expected.nickname)
        expect(actual["attributes"]["avatar"]).to eq(rails_blob_path(@avatar_attached_comparable.reload.avatar))
        expect(actual["attributes"]["contacts"]).to eq(expected.contacts)
        expect(actual["attributes"]["addresses"]).to eq(expected.addresses)
        expect(actual["attributes"]["gender"]).to eq(expected.gender)
        expect(actual["attributes"]["bio"]).to eq(expected.bio)
        expect(actual["attributes"]["birthday"]).to eq(expected.birthday)
        expect(actual["attributes"]["instagram"]).to eq(expected.instagram)


        # Links
        expect(actual["links"]).to eq("self" => api_v1_member_path(id: actual["id"]))

      end
      it "shows default avatar if member doesn't have one attached to their record" do
        # This has a authorized rendering as well including important user info.
        default_avatar_member = @comparables.second.member
        expect(default_avatar_member.avatar.attached?).to be_falsey
        get "/v1/members/#{default_avatar_member.id}", :headers => @auth_headers
        expect(default_avatar_member.reload.avatar.attached?).to be_falsey
        avatar_url = JSON.parse(response.body)["data"]["attributes"]["avatar"]
        default_avatar_url = "assets/images/default_avatar.png"
        expect(avatar_url).to eq(default_avatar_url)
      end
      context ' :: Includes :: ' do
        xit 'and it shows the included Recipes' do
          # trouble with includes via ams
          FactoryBot.create_list(:recipe, 5, member_id: @member.id)
          # currently having trouble getting optional includes
          @include_params = {:include => ["recipes"]}
          get "/v1/members/#{@comparable.id}", :params => @include_params, :headers => @auth_headers
          json = JSON.parse(response.body)
          actual = json["data"]["relationships"]["recipes"]["data"]
          expected = @comparable.event_rsvps
          expect(actual.count).to eq(expected.count)
          
          actual_recipe = actual.first
          expected_recipe = expected.last

          expect(actual_recipe["id"].to_i).to eq(expected_recipe.id)
          expect(actual_recipe["type"].downcase).to eq(expected_recipe.class.to_s.downcase)

          actual_recipe_links = json["data"]["relationships"]["recipes"]["links"]
          expect(actual_recipe_links["related"]).to eq(api_v1_recipes_path(id: actual["id"]))
        end

        xit 'and it shows the included EventRsvps and it\'s Event' do
          # trouble with includes via ams
          # Only RSVP'd Events
          @include_params = {:include => ["event-rsvps"]}
          get "/v1/members/#{@comparable.id}", :params => @include_params, :headers => @auth_headers
          json = JSON.parse(response.body)
          actual = json["data"]["relationships"]["event-rsvps"]["data"]
          expected = @comparable.event_rsvps
          expect(actual.count).to eq(expected.count)
          
          actual_event_rsvp = actual.first
          expected_event_rsvp = expected.last

          expect(actual_event_rsvp["id"].to_i).to eq(expected_event_rsvp.id)
          expect(actual_event_rsvp["type"].downcase).to eq(expected_event_rsvp.class.to_s.downcase)  

          actual_event_rsvp_links = json["data"]["relationships"]["recipes"]["links"]
          expect(actual_event_rsvp_links["related"]).to eq(api_v1_event_path(id: json["data"]["attributes"]["event_id"]))
        end
      end
    end
    context "PUT - PATCH /members/:id Members#update" do
      before do
        @comparable = @member
        update_put = FactoryBot.build(:member_profile, id: @member.id )
        update_patch = FactoryBot.build(:member_profile, id: @member.id )

        @update_put_request_params = {
          "id": @comparable.id,
          "member": {
            "id": @comparable.id,
            "attributes": {
              "name": update_put.name,
              "nickname": update_put.nickname,
              "avatar": @provided_avatar_file,
              "surname": update_put.surname,
              "contacts": update_put.contacts,
              "addresses": update_put.addresses,
              "gender": update_put.gender,
              "bio": update_put.bio,
              "birthday": update_put.birthday,
              "instagram": update_put.instagram
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "member": {
            "id": @comparable.id,
            "attributes": {
              "contacts": update_patch.contacts,
              "addresses": update_patch.addresses,
              "avatar": @provided_avatar_file
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 200 status and matches the json for the putted post" do
        put "/v1/members/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:member][:attributes]

        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["name"]).to eq(expected[:name])
        expect(actual["surname"]).to eq(expected[:surname])
        expect(actual["nickname"]).to eq(expected[:nickname])
        expect(actual["gender"]).to eq(expected[:gender])
        expect(actual["avatar"]).to eq(rails_blob_path(Member.find(json["data"]["id"]).avatar))
        expect(actual["instagram"]).to eq(expected[:instagram])
        expect(actual["birthday"].to_datetime).to eq(expected[:birthday])
        expect(actual["contacts"]).to eq(expected[:contacts])
        expect(actual["addresses"]).to eq(expected[:addresses])


      end
      it "#patch 200 status and can replace a two attributes and it returns the json for the patched post" do
        patch "/v1/members/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:member][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)

        expect(actual["attributes"]["contacts"]).to eq(expected[:contacts])
        expect(actual["attributes"]["addresses"]).to eq(expected[:addresses])
      end
      # trouble with includes via ams
      xit '#patch shows the relationships and links to them in the json package' do
        patch "/v1/members/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
      end
      # trouble with includes via ams
      xit '#put shows the relationships and links to them in the json package' do
        patch "/v1/members/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
      end
      it 'can patch a single media file' do
        file_upload_params = {:member => {:attributes => {:avatar => @provided_avatar_file}}}
        expect(@comparable.avatar.attached?).to_not eq(true)
        patch "/v1/members/#{@comparable.id}", :params => file_upload_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)["data"]["attributes"]["avatar"]
        expect(@comparable.reload.avatar.attached?).to eq(true)
        expect(rails_blob_path(@comparable.reload.avatar)).to eq(json)
      end
    end
    context "DELETE /members/:id Members#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete current_user" do
        delete "/v1/auth/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        expect(json).to eq({"status"=>"success", "message"=>"Account with UID '#{@member.email}' has been destroyed."})
        expect(response).to have_http_status(200)
      end
    end
    context "Unauthorize Inside Family ::" do
      before do
        login_auth(@member)
      end
      context "GET /members Members#update :: Member 2 => Member 1 ::" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
          @second_member = FamilyMember.where(family_id: @member_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
          @updates = FactoryBot.build(:member_profile)
        end
        it "unable to #put update on another family member's profile" do
          unauthorized_update_put_request_params = {
            "id": @second_member.id,
            "member": {
              "id": @second_member.id,
              "attributes": {
                "name": @updates[:name],
                "nickname": @updates[:nickname],
                "avatar": @provided_avatar_file,
                "surname": @updates[:surname],
                "contacts": @updates[:contacts],
                "addresses": @updates[:addresses],
                "gender": @updates[:gender],
                "bio": @updates[:bio],
                "birthday": @updates[:birthday],
                "instagram": @updates[:instagram]
              }
            }
          }


          put "/v1/members/#{@second_member.id}", :params => unauthorized_update_put_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(ActiveStorage::Attachment.all).to be_empty
        end
        it "unable to #patch update on another family member's profile" do
          unauthorized_patch_of_post_params = {
          "id": @second_member.id,
          "member": {
            "id": @second_member.id,
            "attributes": {
              "contacts": @updates[:contacts],
              "addresses": @updates[:addresses],
              "avatar": @provided_avatar_file
            }
          }
        }

          patch "/v1/members/#{@second_member.id}", :params => unauthorized_patch_of_post_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(ActiveStorage::Attachment.all).to be_empty
        end
      end
      context "DELETE /members Members#delete :: Member 2 => Member 1" do
      before(:each) do
        @second_member = FamilyMember.where(family_id: @member_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
        @auth_headers = @member.create_new_auth_token
      end
        it "unable to delete on another family member's profile" do
          delete_request_params = {member: {:id => @second_member.id} }
          delete "/v1/members/#{@second_member.id}", :params => delete_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Admin Role ::' do
    before do
      @second_member = FamilyMember.where(family_id: @member_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
      FamilyMember.where(member_id: @member.id, family_id: @member_family_id).first.update_attributes(user_role: "admin")
      login_auth(@member) # login admin
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
      update_put = FactoryBot.build(:member_profile, id: @member.id )
      update_patch = FactoryBot.build(:member_profile, id: @member.id )

      @update_put_request_params = {
        "id": @second_member.id,
        "member": {
          "id": @second_member.id,
          "attributes": {
            "name": update_put.name,
            "nickname": update_put.nickname,
            "avatar": @provided_avatar_file,
            "surname": update_put.surname,
            "contacts": update_put.contacts,
            "addresses": update_put.addresses,
            "gender": update_put.gender,
            "bio": update_put.bio,
            "birthday": update_put.birthday,
            "instagram": update_put.instagram
          }
        }
      }
      @update_patch_request_params = {
        "id": @second_member.id,
        "member": {
          "id": @second_member.id,
          "attributes": {
            "contacts": update_patch.contacts,
            "addresses": update_patch.addresses,
            "avatar": @provided_avatar_file
          }
        }
      }
    end
    context "PUT-PATCH /members Members#update" do
      it "able to #put update on another family member's profile" do
        put "/v1/members/#{@second_member.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:member][:attributes]
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["name"]).to eq(expected[:name])
        expect(actual["surname"]).to eq(expected[:surname])
        expect(actual["nickname"]).to eq(expected[:nickname])
        expect(actual["gender"]).to eq(expected[:gender])
        expect(actual["avatar"]).to eq(rails_blob_path(Member.find(json["data"]["id"]).avatar))
        expect(actual["instagram"]).to eq(expected[:instagram])
        expect(actual["birthday"].to_datetime).to eq(expected[:birthday])
        expect(actual["contacts"]).to eq(expected[:contacts])
        expect(actual["addresses"]).to eq(expected[:addresses])
      end
      it "able to #patch update on another family member's profile" do
        patch "/v1/members/#{@second_member.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:member][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@second_member.id)

        expect(actual["attributes"]["contacts"]).to eq(expected[:contacts])
        expect(actual["attributes"]["addresses"]).to eq(expected[:addresses])
      end
      it 'can patch a single media file' do
        file_upload_params = {:member => {:attributes => {:avatar => @provided_avatar_file}}}
        expect(@second_member.avatar.attached?).to_not eq(true)
        patch "/v1/members/#{@second_member.id}", :params => file_upload_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)["data"]["attributes"]["avatar"]
        expect(@second_member.reload.avatar.attached?).to eq(true)
        expect(rails_blob_path(@second_member.reload.avatar)).to eq(json)
      end
    end
    context "DELETE /members Members#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a member" do
        @delete_request_params = {:member => {:id => @second_member.id }}
        delete "/v1/members/#{@second_member.id}", :params => @delete_request_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
        expect(FamilyMember.find_by(member_id: @second_member.id)).to eq(nil)
      end
    end
  end # Members / Same Family - Admin Role Describe
  
  describe ':: Members / Unauthorized to Family ::' do
    before do
      @member = FamilyMember.where(family_id: @member_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
      login_auth(@member)
    end
    context "GET /members Members#index" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 and returns scoped members" do
        get '/v1/members', :headers => @auth_headers
        json = JSON.parse(response.body)

        alt_family_member_ids = FamilyMember.where(family_id: @alt_family_id).pluck(:member_id)
        member_family_member_ids = FamilyMember.where(family_id: @member_family_id).pluck(:member_id)

        json["data"].each do |record|
          expect(member_family_member_ids.include?(record["id"].to_i)).to eq(true)
          expect(alt_family_member_ids.include?(record["id"].to_i)).to eq(false)
          record["relationships"]["families"]["data"].each do |subrecord|
            expect(subrecord["id"].to_i).to_not eq(@alt_family_id) if subrecord["type"] == "family"
          end
        end
        expect(response).to have_http_status(200)
      end
    end
    context "GET /members Members#show" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 status code on unauthorized access" do
        non_family_member = FamilyMember.where(family_id: @alt_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
        get "/v1/members/#{non_family_member.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "PUT-PATCH /members Members#update" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      before do
        @comparable = FamilyMember.where(family_id: @alt_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
        update_put = FactoryBot.build(:member_profile, id: @comparable.id )
        update_patch = FactoryBot.build(:member_profile, id: @comparable.id )

        @update_put_request_params = {
          "id": @comparable.id,
          "member": {
            "id": @comparable.id,
            "attributes": {
              "name": update_put.name,
              "nickname": update_put.nickname,
              "avatar": @provided_avatar_file,
              "surname": update_put.surname,
              "contacts": update_put.contacts,
              "addresses": update_put.addresses,
              "gender": update_put.gender,
              "bio": update_put.bio,
              "birthday": update_put.birthday,
              "instagram": update_put.instagram
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "member": {
            "id": @comparable.id,
            "attributes": {
              "contacts": update_patch.contacts,
              "addresses": update_patch.addresses,
              "avatar": @provided_avatar_file
            }
          }
        }
      end
      it "returns 403 error for an unauthorized update put" do
        put "/v1/members/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
      it 'returns 403 error for an unauthorized update patch' do
        patch "/v1/members/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "DELETE /members Members#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized attempt to delete" do
        @comparable = FamilyMember.where(family_id: @alt_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
        @delete_request_params = {member: {:id => @comparable.id } }

        delete "/v1/members/#{@comparable.id}", :params => @delete_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Unauthorized to Family Describe
  describe ':: Unknown User ::' do
    before do
      @comparable = FamilyMember.where(family_id: @alt_family_id).where.not(member_id: @member.id, authorized_at: nil).first.member
      @member = nil
    end
    context "GET /members Members#index" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/members"
        expect(response).to have_http_status(401)
      end
    end
    context "GET /members Members#show" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/members/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "PUT-PATCH /members Members#update" do
      it "#put returns a 401 error saying they are not authenticated" do
        put "/v1/members/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        patch "/v1/members/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /members Members#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        delete "/v1/members/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe


end
