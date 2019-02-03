require 'rails_helper'

RSpec.describe "Events API", type: :request do
  before do
    @family = FactoryBot.create(:family)
    family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
    @member = family_member.member
    @member_family_id = family_member.family_id
    @image_file = fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg')
    @image_filename = 'img.jpg'
    @image_content_type = 'image/jpg'
  end
  describe ':: Members / Same Family ::' do
    before do
      login_auth(@member)
    end
    context "GET /events Events#index" do
      before do
        5.times { FactoryBot.create(:event, family_id: @member_family_id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id, ).member_id ) }
        @comparable = Event.where(family_id: @member.families.ids)
        @comparable.pluck(:id).each {|id| FactoryBot.create(:event_rsvp, event_id: id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id)}
        @media_attached_comparable = @comparable.first
        @media_attached_comparable.media.attach(io: File.open(@image_file), filename: @image_filename, content_type: @image_content_type)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 200 status" do
        get '/v1/events', :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and can get all of the records available to the Member\'s policy via index' do
        get '/v1/events', :headers => @auth_headers

        json = JSON.parse(response.body) 
        expected = @comparable.pluck(:id)
        actual = []
        json["data"].each {|data| actual << data["id"].to_i}
        expect(actual.sort).to eq(expected.sort)
        expect(json["data"].count).to eq(@comparable.count)
        expect(response).to have_http_status(200)
      end
      it 'and getting the index returns the count and type of reactions for each record' do
        get '/v1/events', :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.reactions
        actual = json["data"].first["relationships"]["reactions"]["data"]
        expect(actual).to eq(expected)
      end
      it 'and getting the index returns the comment records' do
        get '/v1/events', :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.comments
        actual = json["data"].first["relationships"]["comments"]
        expect(actual).to include("links")
        expect(actual["data"]).to eq(expected)
      end
      it 'shows links to relevant resources' do
        get '/v1/events', :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"].first["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
        expect(actual).to include("family")
      end
      it 'the serializer should attach the blob path or return nil for other 4' do
        get '/v1/posts', :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        json.each do |data|
          if data["id"].to_i == @media_attached_comparable.id
            expect(data["attributes"]["media"]).to eq(rails_blob_path(@media_attached_comparable.media))
          else
            expect(data["attributes"]["media"]).to eq(nil)
          end
        end
      end
    end
    context "GET /events/:id Events#show" do
      before do
        @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id )
        FactoryBot.create(:event_rsvp, event_id: @comparable.id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id)
        FactoryBot.create_list(:comment, 2, commentable_type: "Event", commentable_id: @comparable.id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id)
        FactoryBot.create(:reaction, interaction_type: "Event", interaction_id: @comparable.id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id)
        @comparable.media.attach(io: File.open(@image_file), filename: @image_filename, content_type: @image_content_type)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "shows 200 status and matches comparable" do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers

        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]


        expect(response).to have_http_status(200)
        expect(json["data"]["id"].to_i).to eq(@comparable.id)
        expect(actual["title"]).to eq(@comparable.title)
        expect(actual["description"]).to eq(@comparable.description)
        expect(actual["media"]).to eq(rails_blob_path(@comparable.media))
        expect(actual["potluck"]).to eq(@comparable.potluck)
        expect(actual["event-allday"]).to eq(@comparable.event_allday)
        expect(actual["event-start"].to_datetime).to eq(@comparable.event_start.to_datetime)
        expect(actual["event-end"].to_datetime).to eq(@comparable.event_end.to_datetime)
        expect(actual["locked"]).to eq(@comparable.locked)
        expect(actual["family-id"]).to eq(@comparable.family_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)

        expect(actual["location"][0]).to be_within(0.000000000009).of(@comparable.location[0])
        expect(actual["location"][1]).to be_within(0.000000000009).of(@comparable.location[1])
      end
      it 'and it shows the requested post\'s Comments' do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]["comments"]["data"] # array of comments

        expected_comments = @comparable.comments.pluck(:id).sort
        actual_comments = []
        json["data"]["relationships"]["comments"]["data"].each {|data| actual_comments << data["id"].to_i}
        actual_comments = actual_comments.sort
        expect(actual.count).to eq(@comparable.comments.count)
        expect(actual_comments.first).to eq(expected_comments.first)
        json["data"]["relationships"]["comments"]["data"].each {|data| expect(data["type"]).to eq(@comparable.comments.first.class.to_s.downcase)}
      end
      it 'and it shows the requested post\'s Reactions' do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]["reactions"]["data"]
        expected = @comparable.reactions
        expect(actual.count).to eq(expected.count)
        
        actual_reaction = actual.first
        expected_reaction = expected.last

        expect(actual_reaction["id"].to_i).to eq(expected_reaction.id)
        expect(actual_reaction["type"].downcase).to eq(expected_reaction.class.to_s.downcase)   
      end
      it 'shows the relationships and links to them in the json package' do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        
        actual_event_links = json["data"]["links"]
        actual_member_links = json["data"]["relationships"]["member"]["links"]
        actual_reaction_links = json["data"]["relationships"]["reactions"]["links"]
        actual_comment_links = json["data"]["relationships"]["comments"]["links"]

        expected_resource = @comparable
        expected_member = @comparable.member
        expected_reaction = @comparable.reactions.first
        expected_comment = @comparable.comments.first

        expect(json["data"]["id"].to_i).to eq(@comparable.id)
        expect(actual_event_links["self"]).to include("#{@comparable.id}")

        expect(actual_member_links["related"]).to include("member","#{@comparable.member.id}")

        expect(actual_reaction_links["related"]).to include("reactions","#{@comparable.id}")

        expect(actual_comment_links["related"]).to include("comments","#{@comparable.id}")

      end
      it 'shows the includes in the json package' do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["included"].first
        actual_attributes = actual["attributes"]
        expect(json["data"]["id"]).to eq(json["included"].first["relationships"]["event"]["data"]["id"])
        expect(actual).to include("id")
        expect(actual["type"]).to include("event-rsvp")
        expect(actual_attributes).to include("party-size")
        expect(actual_attributes).to include("rsvp")
        expect(actual_attributes).to include("bringing-food")
        expect(actual_attributes).to include("recipe-id")
        expect(actual_attributes).to include("non-recipe-description")
        expect(actual_attributes).to include("serving")
        expect(actual_attributes).to include("member-id")
        expect(actual_attributes).to include("party-companions")
        expect(actual_attributes).to include("event-id")
        expect(actual_attributes).to include("rsvp-note")
      end
    end
    context "POST /events Events#create" do
      before do
       @comparable = FactoryBot.build(:event, family_id: @member_family_id, member_id: @member.id )
       @create_request_params = {
          "event": {
            "attributes": {
              "title": @comparable.title,
              "description": @comparable.description,
              "location": @comparable.location,
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "event_start": @comparable.event_start,
              "event_end": @comparable.event_end,
              "media": @image_file
            }
          }
        }
      @create_request_params_without_dates = {
          "event": {
            "attributes": {
              "title": @comparable.title,
              "description": @comparable.description,
              "location": @comparable.location,
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "media": @image_file
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status" do
        post '/v1/events', :params => @create_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(response).to have_http_status(200)
      end
      it 'and it returns the json for the newly created post' do
        post '/v1/events', :params => @create_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(@comparable.title)
        expect(actual["description"]).to eq(@comparable.description)
        expect(actual["family-id"]).to eq(@comparable.family_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["event-start"].to_datetime).to eq(@comparable.event_start.to_datetime)
        expect(actual["event-end"].to_datetime).to eq(@comparable.event_end.to_datetime)
        expect(actual["media"]).to eq(rails_blob_path(Event.find(json["data"]["id"]).media))
      end
      it 'and without date input it defaults to current day' do
        post '/v1/events', :params => @create_request_params_without_dates, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(@comparable.title)
        expect(actual["description"]).to eq(@comparable.description)
        expect(actual["family-id"]).to eq(@comparable.family_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["event-start"].to_datetime).to eq(DateTime.parse("#{Date.today} 00:00:00"))
        expect(actual["event-end"].to_datetime).to eq(DateTime.parse("#{Date.today} 23:59:59"))
        expect(actual["media"]).to eq(rails_blob_path(Event.find(json["data"]["id"]).media))
      end
      it 'shows the relationships and links to them in the json package' do
        post '/v1/events', :params => @create_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
        expect(actual).to include("family")
        expect(actual).to include("event-rsvps")
      end
      it 'shows the includes in the json package' do
        post '/v1/events', :params => @create_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["included"].first
        actual_attributes = actual["attributes"]
        expect(json["data"]["id"]).to eq(json["included"].first["relationships"]["event"]["data"]["id"])
        expect(actual).to include("id")
        expect(actual["type"]).to include("event-rsvp")
        expect(actual_attributes).to include("party-size")
        expect(actual_attributes).to include("rsvp")
        expect(actual_attributes).to include("bringing-food")
        expect(actual_attributes).to include("recipe-id")
        expect(actual_attributes).to include("non-recipe-description")
        expect(actual_attributes).to include("serving")
        expect(actual_attributes).to include("member-id")
        expect(actual_attributes).to include("party-companions")
        expect(actual_attributes).to include("event-id")
        expect(actual_attributes).to include("rsvp-note")
      end
    end
    context "PUT - PATCH /events/:id Events#update" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: @member.id )
        update = FactoryBot.build(:event, family_id: @member_family_id, member_id: @member.id )
        @update_put_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "title": update.title,
              "description": update.description,
              "location": update.location,
              "media": @image_file,
              "locked": update.locked,
              "created_at": update.created_at,
              "updated_at": update.updated_at
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "title": update.title,
              "media": @image_file
            }
          }
        }
      end
      it "#put 200 status and matches the json for the putted post" do
        put "/v1/events/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:event][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(expected[:title])
        expect(actual["location"]).to eq(expected[:location])
        expect(actual["family-id"]).to eq(expected[:family_id])
        expect(actual["member-id"]).to eq(expected[:member_id])
        expect(actual["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual["description"]).to eq(expected[:description])
        expect(actual["created-at"].to_datetime).to_not eq(expected[:created_at])
        expect(actual["updated-at"].to_datetime).to_not eq(expected[:updated_at])
      end
      it "#patch 200 status and can replace a single attribute and it returns the json for the patched post" do
        patch "/v1/events/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:event][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual["attributes"]["title"]).to eq(expected[:title])
        expect(actual["attributes"]["description"]).to eq(@comparable.description)
        expect(actual["attributes"]["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual["attributes"]["locked"]).to eq(@comparable.locked)
        expect(actual["attributes"]["family-id"]).to eq(@comparable.family_id)
        expect(actual["attributes"]["member-id"]).to eq(@comparable.member_id)
        actual["attributes"]["location"].each_with_index do |v, i|
          expect(actual["attributes"]["location"][i]).to be_within(0.000000000009).of(@comparable.location[i])
        end
      end
      it '#patch shows the relationships and links to them in the json package' do
        patch "/v1/events/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
        expect(actual).to include("event-rsvps")
      end
      it '#put shows the relationships and links to them in the json package' do
        patch "/v1/events/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comments")
        expect(actual).to include("member")
        expect(actual).to include("event-rsvps")
      end
      it 'can patch a single media file' do
        file_upload_params = {:event => {:attributes => {:media => @image_file}}}
        expect(@comparable.media.attached?).to_not eq(true)
        patch "/v1/events/#{@comparable.id}", :params => file_upload_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)["data"]["attributes"]["media"]
        expect(@comparable.reload.media.attached?).to eq(true)
        expect(rails_blob_path(@comparable.reload.media)).to eq(json)
      end
    end
    context "DELETE /events/:id Events#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a post" do
        @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: @member.id )
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/events/#{@comparable.id}", :params => @delete_request_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it 'returns 404 for missing content' do
        @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: @member.id )
        @delete_request_params = {:id => @comparable.id }
        Event.find(@comparable.id).destroy
        delete "/v1/events/#{@comparable.id}", :params => @delete_request_params, :headers => @auth_headers
        json = JSON.parse(response.body) 
        expect(json).to eq({})
        expect(response).to have_http_status(404)
      end
    end
    context "Unauthorize Inside Family ::" do
      before do
        @member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
        @second_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
        login_auth(@member)
      end
      context "PUT-PATCH /events Events#update :: Member 2 => Member 1 ::" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
          @comparable = FactoryBot.create(:event, family_id: @family.id, member_id: @second_member.id )
          @updates = FactoryBot.build(:event, id: @comparable.id, family_id: @family.id, member_id: @member.id, locked: true )
        end
        it "unable to #put update on another family member's post" do
          unauthorized_update_put_request_params = {
            "id": @updates[:id],
            "event": {
              "id": @updates[:id],
              "attributes": {
                "family_id": @updates[:family_id],
                "member_id": @updates[:member_id],
                "title": @updates[:title],
                "location": @updates[:location],
                "description": @updates[:description],
                "media": @image_file,
                "locked": @updates[:locked],
                "updated_at": @updates[:updated_at]
              }
            }
          }

          put "/v1/events/#{@comparable.id}", :params => unauthorized_update_put_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(ActiveStorage::Attachment.all).to be_empty
        end
        it "unable to #patch update on another family member's post" do
          unauthorized_patch_of_post_params = {
            "id": @updates[:id],
            "event": {
              "title": @updates[:title]
            }
          }

          patch "/v1/events/#{@comparable.id}", :params => unauthorized_patch_of_post_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
          expect(ActiveStorage::Attachment.all).to be_empty
        end
        it "unable to #patch update on a protected field" do
          update_patch_request_unpermitted_params = {
            "id": @updates[:id],
            "event": {
              "id": @updates[:id],
              "family_id": @updates[:family_id],
              "member_id": @updates[:member_id],
              "description": @updates[:description],
              "locked": @updates[:locked],
              "created_at": @updates[:created_at]
            }
          }
          patch "/v1/events/#{@comparable.id}", :params => update_patch_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #put update on a protected field" do
          update_put_request_unpermitted_params = {
            "id": @updates[:id],
            "event": {
              "id": @updates[:id],
              "family_id": @updates[:family_id],
              "member_id": @updates[:member_id],
              "description": @updates[:description],
              "locked": @updates[:locked],
              "created_at": @updates[:created_at]
            }
          }
          put "/v1/events/#{@comparable.id}", :params => update_put_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "DELETE /events Events#delete :: Member 2 => Member 1" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
        end
        it "unable to delete on another family member's post" do
          @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: FactoryBot.create(:family_member, family_id: @member_family_id ).member_id )
          delete_request_params = {:id => @comparable.id }
          delete "/v1/events/#{@comparable.id}", :params => delete_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Admin Role ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, user_role: "admin", authorized_at: DateTime.now)
      @member = family_member.member # admin
      @member_family_id = @family.id
      @normal_member = FactoryBot.create(:family_member, family_id: @family.id).member # normal user
      login_auth(@member) # login admin
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
      @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: @normal_member.id )
      update = FactoryBot.build(:event, family_id: @member_family_id, member_id: @member.id )
      @update_put_request_params = {
        "id": @comparable.id,
        "event": {
          "id": @comparable.id,
          "attributes": {
            "family_id": @comparable.family_id,
            "member_id": @comparable.member_id,
            "title": update.title,
            "description": update.description,
            "location": update.location,
            "media": @image_file,
            "locked": update.locked,
            "created_at": update.created_at,
            "updated_at": update.updated_at
          }
        }
      }
      @update_patch_request_params = {
        "id": @comparable.id,
        "event": {
          "id": @comparable.id,
          "attributes": {
            "title": update.title,
            "media": @image_file
          }
        }
      }
    end
    context "PUT-PATCH /events Events#update" do
      it "able to #put update on another family member's post" do
        put "/v1/events/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:event][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(expected[:title])
        expect(actual["location"]).to eq(expected[:location])
        expect(actual["family-id"]).to eq(@comparable.family_id) # actual vs expected tested in Unauthorized to Family
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual["description"]).to eq(expected[:description])
        expect(actual["created-at"]).to_not eq(expected[:created_at])
        expect(actual["updated-at"]).to_not eq(expected[:updated_at])
      end
      it "able to #patch update on another family member's post" do
        patch "/v1/events/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:event][:attributes]
        
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(expected[:title]) # updated
        expect(actual["location"][0]).to be_within(0.000000000009).of(@comparable.location[0])
        expect(actual["location"][1]).to be_within(0.000000000009).of(@comparable.location[1])
        expect(actual["family-id"]).to eq(@comparable.family_id) # actual vs expected tested in Unauthorized to Family
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual["description"]).to eq(@comparable.description)
        expect(actual["created-at"]).to_not eq(@comparable.created_at)
        expect(actual["updated-at"]).to_not eq(@comparable.updated_at)
      end
    end
    context "DELETE /events Events#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a post" do
        @comparable = FactoryBot.create(:event, family_id: @member_family_id, member_id: @member.id )
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/events/#{@comparable.id}", :params => @delete_request_params, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
    end
  end # Members / Same Family - Admin Role Describe
  
  describe ':: Members / Unauthorized to Family ::' do
    before do
      authorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @authorized_member_family_id = authorized_member.family_id
      @authorized_member = authorized_member.member


      unauthorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @unauthorized_member_family_id = unauthorized_member.family_id
      @member = unauthorized_member.member
      login_auth(@member)
    end
    context "GET /events Events#index" do
      before do
        FactoryBot.create_list(:event, 5, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
        @comparable = Event.where(family_id: @authorized_member_family_id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 and returns 0 posts" do
        get '/v1/events', :headers => @auth_headers
        json = JSON.parse(response.body) 
        expected = @comparable
        actual = json["data"]
        expect(actual.count).to_not eq(expected.count)
        expect(actual.count).to eq(0)
        expect(response).to have_http_status(200)
      end
      it '200 and returns 1 post in it\'s own family but can\'t see scoped posts' do
        expected = FactoryBot.create(:event, family_id: @unauthorized_member_family_id, member_id: @member.id)
        get '/v1/events', :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]
        scoped_post_all = Event.where(family_id: [@unauthorized_member_family_id, @authorized_member_family_id])
        expect(actual.count).to eq(1)
        expect(actual.first["attributes"]["title"]).to eq(expected.title)
        expect(scoped_post_all.count).to eq(6)
      end
    end
    context "GET /events Events#show" do
      before do
        @comparable = FactoryBot.create(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 status code on unauthorized access" do
        get "/v1/events/#{@comparable.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "POST /events Events#create" do
      before do
        @comparable = FactoryBot.build(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
        @create_request_params = {
          "event": {
            "attributes": {
              "title": @comparable.title,
              "description": @comparable.description,
              "location": @comparable.location,
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "event_start": @comparable.event_start,
              "event_end": @comparable.event_end,
              "media": @image_file
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "unable to create a post in another family" do
        post "/v1/events", :params => @create_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "PUT-PATCH /events Events#update" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      before do
        @comparable = FactoryBot.create(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
        update = FactoryBot.build(:event, family_id: @unauthorized_member_family_id, member_id: @member.id )
        @update_put_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "title": update.title,
              "location": update.location,
              "description": update.description,
              "media": @image_file,
              "locked": update.locked,
              "created_at": update.created_at,
              "updated_at": update.updated_at
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "title": update.title,
              "media": @image_file
            }
          }
        }
      end
      it "returns 403 error for an unauthorized update put" do
        put "/v1/events/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
      it 'returns 403 error for an unauthorized update patch' do
        patch "/v1/events/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "DELETE /events Events#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized attempt to delete" do
        @comparable = FactoryBot.create(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id )
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/events/#{@comparable.id}", :params => @delete_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Unauthorized to Family Describe
  describe ':: Unknown User ::' do
    before do
      authorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @authorized_member_family_id = authorized_member.family_id
      @authorized_member = authorized_member.member

      @member = nil
      FactoryBot.create_list(:event, 2, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
      @comparable = Event.where(family_id: @authorized_member_family_id)
    end
    context "GET /events Events#index" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/events"
        expect(response).to have_http_status(401)
      end
    end
    context "GET /events Events#show" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/events/#{@comparable.first.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "POST /events Events#create" do
      it "returns a 401 error saying they are not authenticated" do
        comparable_for_create = FactoryBot.build(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
        @create_request_params = {
          "event": {
            "attributes": {
              "title": comparable_for_create.title,
              "description": comparable_for_create.description,
              "location": comparable_for_create.location,
              "family_id": comparable_for_create.family_id,
              "member_id": comparable_for_create.member_id,
              "event_start": comparable_for_create.event_start,
              "event_end": comparable_for_create.event_end,
              "media": @image_file
            }
          }
        }
        post "/v1/events", :params => @comparable_for_create
        expect(response).to have_http_status(401)
        expect(ActiveStorage::Attachment.all).to be_empty
        
      end
    end
    context "PUT-PATCH /events Events#update" do
      before do
        @comparable = FactoryBot.create(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id )
        update = FactoryBot.build(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id )
        @update_put_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "family_id": @comparable.family_id,
              "member_id": @comparable.member_id,
              "title": update.title,
              "location": update.location,
              "description": update.description,
              "media": @image_file,
              "locked": update.locked,
              "created_at": update.created_at,
              "updated_at": update.updated_at
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "event": {
            "id": @comparable.id,
            "attributes": {
              "title": update.title,
              "media": @image_file
            }
          }
        }
      end
      it "#put returns a 401 error saying they are not authenticated" do
        put "/v1/events/#{@comparable.id}", :params => @update_put_request_params
        expect(response).to have_http_status(401)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        patch "/v1/events/#{@comparable.id}", :params => @update_patch_request_params
        expect(response).to have_http_status(401)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "DELETE /events Events#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        @comparable = FactoryBot.create(:event, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/events/#{@comparable.id}", :params => @delete_request_params
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe


end
