require 'rails_helper'

RSpec.describe "CommentReplies", type: :request do
  before do
    @family = FactoryBot.create(:family)
    family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
    @member = family_member.member
    @member_family_id = @family.id
  end
  describe ':: Members / Same Family ::' do
    before do
      @parent = FactoryBot.create(:post, family_id: @member_family_id, member_id: @member.id)
      @parent_class = @parent.class.to_s.pluralize.downcase
      @subject = FactoryBot.create(:comment, commentable_type: @parent.class.to_s, commentable_id: @parent.id, member_id: @member.id)
      login_auth(@member)
    end
    context "GET parent/:id/comments/:id/comment_replys CommentReply#index" do
      before do
        @comparable = FactoryBot.create_list(:comment_reply, 5, comment_id: @subject.id, member_id: @member.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 200 status" do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and can get all of the records available to the Member\'s policy via index' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :headers => @auth_headers

        json = JSON.parse(response.body) 
        expected_ids = @comparable.pluck(:id)
        actual = json["data"].first
        expect(expected_ids).to include(actual["id"].to_i)
        expect(json["data"].count).to eq(@comparable.count)
        expect(response).to have_http_status(200)
      end
      it 'and getting the index returns the count and type of reactions for each record' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.reactions
        actual = json["data"].first["relationships"]["reactions"]["data"]
        expect(actual).to eq(expected)
      end
      it 'and getting the index returns the comment record' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.comment
        actual = json["data"].first["relationships"]["comment"]
        expect(actual["data"]["id"].to_i).to eq(expected.id)
        expect(actual["data"]["type"]).to eq(expected.class.to_s.downcase)
      end
      it 'shows relevant resources' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        
        json = JSON.parse(response.body)
        actual = json["data"].first["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("comment")
        expect(actual).to include("member")
      end
    end
    context "GET parent/:parent_id/comments/:comment_id/comment_replys/:id CommentReply#show" do
      before do
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @member.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "shows 200 status and matches comparable" do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :headers => @auth_headers

        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]

        expect(response).to have_http_status(200)
        expect(json["data"]["id"].to_i).to eq(@comparable.id)
        expect(actual["body"]).to eq(@comparable.body)
        expect(actual["edit"]).to eq(@comparable.edit)
        expect(actual["comment-id"]).to eq(@comparable.comment_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)

      end
      it 'and it shows reactions, comment, and member' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("comment")
        expect(actual["comment"]).to include("data")

        expect(actual).to include("member")
        expect(actual["member"]).to include("data")

        expect(actual).to include("reactions")
        expect(actual["reactions"]).to include("data")
      end
      it 'it shows links in the attributes' do
        get "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]["links"]
        expect(actual).to include("self")
        expect(actual["self"]).to include(api_v1_comment_comment_reply_path(@subject.id, json["data"]["id"].to_i))

        expect(actual).to include("comment")
        expect(actual["comment"]).to include(api_v1_comment_path(@subject.id))

        expect(actual).to include("member")
        expect(actual["member"]).to include(api_v1_member_path(json["data"]["attributes"]["member-id"].to_i))
      end
    end
    context "POST parent/:parent_id/comments/:comment_id/comment_replys CommentReply#create" do
      before do
       @comparable = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @member.id)
       @create_request_params = {
            "attributes": {
              "body": @comparable.body,
              "comment_id": @comparable.comment_id,
              "member_id": @comparable.member_id
            }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status for principle route" do
        post "/v1/comments/#{@subject.id}/comment_replys", :params => {:comment_reply => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "200 status for subject nested route" do
        post "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys", :params => {:comment_reply => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and it returns the json for the newly created comment' do
        post "/v1/comments/#{@subject.id}/comment_replys", :params => {:comment_reply => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        comparable_id = CommentReply.where(comment_id: @comparable.comment_id, member_id: @comparable.member_id, body: @comparable.body).first.id
        expect(json["data"]["id"].to_i).to eq(comparable_id)
        expect(actual["body"]).to eq(@comparable.body)
        expect(actual["edit"]).to eq(@comparable.edit)
        expect(actual["comment-id"]).to eq(@comparable.comment_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)
      end
      it 'shows the relationships and links to them in the json package' do
        post "/v1/comments/#{@subject.id}/comment_replys", :params => {:comment_reply => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("comment")
        expect(actual).to include("reactions")
        expect(actual).to include("member")

        expect(actual["comment"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
    end
    context "PUT - PATCH parent/:parent_id/comments/:subject_id/comment_replys/:id CommentReply#update" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @member.id)
        update = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @member.id)
        @update_put_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "comment_id": @subject.id,
              "member_id": @comparable.member_id,
              "body": update.body,
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body
            }
          }
        }
      end
      it "#put 200 status with nested subject route" do
        put "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "#patch 200 status with nested subject route" do
        patch "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "#put 200 status and matches the json for the putted comment" do
        put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment_reply][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["comment-id"]).to eq(@comparable.comment_id)
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it "#patch 200 status and can replace a single attribute and it returns the json for the patched comment" do
        patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:comment_reply][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["comment-id"]).to eq(@comparable.comment_id)
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it '#patch shows the relationships and links to them in the json package' do
        patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("comment")
        expect(actual).to include("reactions")
        expect(actual).to include("member")

        expect(actual["comment"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
      it '#put shows the relationships and links to them in the json package' do
        put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("comment")
        expect(actual).to include("reactions")
        expect(actual).to include("member")

        expect(actual["comment"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
    end
    context "DELETE parent/:parent_id/comments/:subject_id/comment_replys/:id CommentReply#destroy" do
      before(:each) do
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @member.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a comment via nested subject route" do
        delete_request_params = {:id => @comparable.id }
        delete "/v1/#{@parent_class}/#{@parent.id}/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => {comment_reply: delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it "can sucessfully delete a comment" do
        delete_request_params = {:id => @comparable.id }
        delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => {comment_reply: delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it 'returns 404 for missing content' do
        deleted_comparable_id = @comparable.id
        delete_request_params = {:id => deleted_comparable_id }
        CommentReply.find(deleted_comparable_id).destroy
        delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => {comment_reply: delete_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body) 
        expect(json).to eq({})
        expect(response).to have_http_status(404)
      end
    end
    context "Unauthorize Inside Family ::" do
      before do
        @second_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
      end
      context "PUT-PATCH comments/:subject_id/comment_replys/:id CommentReply#update :: Member 2 => Member 1 ::" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
          @update_subject = FactoryBot.create(:comment, commentable_type: @parent.class.to_s, commentable_id: @parent.id, member_id: @member.id)
          @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @second_member.id)
          @updates = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @member.id)
        end
        it "unable to #put update on another family member's comment" do
          unauthorized_update_put_request_params = {
            "id": @comparable[:id],
            "comment_reply": {
              "id": @comparable[:id],
              "attributes": {
                "comment_id": @subject.id,
                "member_id": @updates[:member_id],
                "body": @updates[:body]
              }
            }
          }

          put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => unauthorized_update_put_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #patch update on another family member's comment" do
          unauthorized_patch_of_post_params = {
            "id": @comparable[:id],
            "comment_reply": {
              "attributes": {
              "body": @updates[:body]
              }
            }
          }

          patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => unauthorized_patch_of_post_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #patch update on a protected field" do
          update_patch_request_unpermitted_params = {
            "id": @comparable[:id],
            "comment_reply": {
              "id": @comparable[:id],
              "attributes": {
              "comment_id": @subject.id,
              "member_id": @updates[:member_id],
              "body": @updates[:body]
              }
            }
          }
          patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => update_patch_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #put update on a protected field" do
          update_put_request_unpermitted_params = {
            "id": @comparable[:id],
            "comment_reply": {
              "id": @comparable[:id],
              "attributes": {
                "comment_id": @subject.id,
                "member_id": @updates[:member_id],
                "body": @updates[:body]
              }
            }
          }
          put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => update_put_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "DELETE comments/:subject_id/comment_replys/:id CommentReply#delete :: Member 2 => Member 1" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
        it "unable to delete on another family member's comment" do
          @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @second_member.id)
          delete_request_params = {comment_reply: {:id => @comparable.id }}
          delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => delete_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Admin Role ::' do
    before do
      @parent = FactoryBot.create(:post, family_id: @member_family_id, member_id: @member.id)
      @parent_class = @parent.class.to_s.pluralize.downcase
      @subject = FactoryBot.create(:comment, commentable_type: @parent.class.to_s, commentable_id: @parent.id, member_id: @member.id)

      family_member = FactoryBot.create(:family_member, family_id: @family.id, user_role: "admin", authorized_at: DateTime.now)
      @member = family_member.member # admin
      @member_family_id = @family.id
      @normal_member = FactoryBot.create(:family_member, family_id: @family.id).member # normal user
      login_auth(@member) # login admin
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
      @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @member.id)
      update = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @member.id)
      @update_put_request_params = {
        "id": @comparable.id,
        "comment_reply": {
          "id": @comparable.id,
          "attributes": {
            "comment_id": @subject.id,
            "member_id": @comparable.member_id,
            "body": update.body,
          }
        }
      }
      @update_patch_request_params = {
        "id": @comparable.id,
        "comment_reply": {
          "id": @comparable.id,
          "attributes": {
            "body": update.body
          }
        }
      }
    end
    context "PUT-PATCH /comments CommentReply#update" do
      it "able to #put update on another family member's comment" do
        put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment_reply][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]

        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["comment-id"]).to eq(@comparable.comment_id)
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it "able to #patch update on another family member's comment" do
        patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment_reply][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["comment-id"]).to eq(@comparable.comment_id)
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
    end
    context "DELETE /comments CommentReply#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a comment" do
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => {comment: @delete_request_params}, :headers => @auth_headers
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
      @parent = FactoryBot.create(:post, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
      @subject = FactoryBot.create(:comment, commentable_type: @parent.class.to_s, commentable_id: @parent.id, member_id: @authorized_member.id)

      unauthorized_member = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @unauthorized_member_family_id = unauthorized_member.family_id
      @unauthorized_member = unauthorized_member.member
    end
    context "GET /comments CommentReply#index" do
      # This only applys to Recipes as comment because each recipe belongs to a member.
      # Hypothetically, you could have one user (family A and B) who is apart of two families where the
      # third user (member of family B) is unable to see first user's comment (family A).
      before do
        @authorized_comparable = FactoryBot.create_list(:comment_reply, 2, comment_id: @subject.id, member_id: @authorized_member.id)
      end
      after(:each) do
        logout_auth(@member)
      end
      it "200 and returns 0 comment_reply for unauthorized_member" do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @auth_headers = @member.create_new_auth_token
        get "/v1/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(actual.count).to eq(0)
        expect(response).to have_http_status(200)
      end
      it "200 and returns 2 comment_replys for authorized_member" do
        login_auth(@authorized_member) # @member = @authorized_member
        @auth_headers = @member.create_new_auth_token
        get "/v1/comments/#{@subject.id}/comment_replys", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(@authorized_comparable.pluck(:id)).to include(actual.first["id"].to_i)
        expect(@authorized_comparable.pluck(:id)).to include(actual.last["id"].to_i)
        expect(actual.count).to eq(2)
        expect(response).to have_http_status(200)
      end
    end
    context "GET /comments CommentReply#show" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 status code on unauthorized access" do
        get "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "POST /comments CommentReply#create" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
        @create_request_params = {
          "comment_reply": {
            "attributes": {
              "body": @comparable.body,
              "comment_id": @comparable.comment_id,
              "member_id": @comparable.member_id
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "unable to create a comment in another family" do
        post "/v1/comments/#{@subject.id}/comment_replys", :params => @create_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "PUT-PATCH /comments CommentReply#update" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
        update = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
        @update_put_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "comment_id": @subject.id,
              "member_id": @comparable.member_id,
              "body": update.body
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized update put" do
        put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it 'returns 403 error for an unauthorized update patch' do
        patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "DELETE /comments CommentReply#destroy" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized attempt to delete" do
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => {comment_reply: @delete_request_params}, :headers => @auth_headers
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
      @parent = FactoryBot.create(:post, family_id: @authorized_member_family_id, member_id: @authorized_member.id)
      @subject = FactoryBot.create(:comment, commentable_type: @parent.class.to_s, commentable_id: @parent.id, member_id: @authorized_member.id)
      @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
    end
    context "GET /comments CommentReply#index" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/comments/#{@subject.id}/comment_replys"
        expect(response).to have_http_status(401)
      end
    end
    context "GET /comments CommentReply#show" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "POST /comments CommentReply#create" do
      it "returns a 401 error saying they are not authenticated" do
        comparable_for_create = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: nil)
        @create_request_params = {
          "comment_reply": {
            "attributes": {
              "body": comparable_for_create.body,
              "comment_id": comparable_for_create.comment_id,
              "member_id": comparable_for_create.member_id
            }
          }
        }
        post "/v1/comments/#{@subject.id}/comment_replys", :params => @comparable_for_create
        expect(response).to have_http_status(401)
      end
    end
    context "PUT-PATCH /comments CommentReply#update" do
      before do
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id)
        update = FactoryBot.build(:comment_reply, comment_id: @subject.id, member_id: nil)
        @update_put_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body,
              "comment_id": update.comment_id,
              "member_id": update.member_id
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment_reply": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body
            }
          }
        }
      end
      it "#put returns a 401 error saying they are not authenticated" do
        put "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_put_request_params
        expect(response).to have_http_status(401)
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        patch "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @update_patch_request_params
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /comments CommentReply#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        @comparable = FactoryBot.create(:comment_reply, comment_id: @subject.id, member_id: @authorized_member.id )
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/comments/#{@subject.id}/comment_replys/#{@comparable.id}", :params => @delete_request_params
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe


end
