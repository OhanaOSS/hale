require 'rails_helper'
RSpec.describe "Comment API", type: :request do
  before do
    @family = FactoryBot.create(:family)
    family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
    @member = family_member.member
    @member_family_id = @family.id
    @image_file = fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg')
    @image_filename = 'img.jpg'
    @image_content_type = 'image/jpg'
  end
  describe ":: Compatability" do
    it "with Posts works." do
      post = FactoryBot.create(:post, family_id: @member_family_id, member_id: @member.id)
      comment = FactoryBot.create(:comment, commentable_type: "Post", commentable_id: post.id, member_id: @member.id)
      expect(comment).to_not be nil
      expect(post.comments.first).to eq(comment)
    end
    it "with Recipes works." do
      recipe = FactoryBot.create(:recipe, member_id: @member.id)
      comment = FactoryBot.create(:comment, commentable_type: "Recipe", commentable_id: recipe.id, member_id: @member.id)
      expect(comment).to_not be nil
      expect(recipe.comments.first).to eq(comment)
    end
    it "with Events works." do
      event = FactoryBot.create(:event, family_id: @member_family_id, member_id: @member.id)
      comment = FactoryBot.create(:comment, commentable_type: "Event", commentable_id: event.id, member_id: @member.id)
      expect(comment).to_not be nil
      expect(event.comments.first).to eq(comment)
    end
  end
  describe ':: Members / Same Family ::' do
    before do
      @subjects = FactoryBot.create_list(:post, 5, family_id: @member_family_id, member_id: @member.id)
      @subject = @subjects.first
      @subject_class = @subject.class.to_s.pluralize.downcase
      login_auth(@member)
    end
    context "GET subject/:id/comments Comments#index" do
      before do
        @comparable = FactoryBot.create_list(:comment, 5, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        @media_attached_comparable = @comparable.first
        @media_attached_comparable.media.attach(io: File.open(@image_file), filename: @image_filename, content_type: @image_content_type)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 200 status" do
        get "/v1/#{@subject_class}/#{@subject.id}/comments", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and can get all of the records available to the Member\'s policy via index' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments", :headers => @auth_headers

        json = JSON.parse(response.body) 
        expected_ids = @comparable.pluck(:id)
        actual = json["data"].first
        expect(expected_ids).to include(actual["id"].to_i)
        expect(json["data"].count).to eq(@comparable.count)
        expect(response).to have_http_status(200)
      end
      it 'and getting the index returns the count and type of reactions for each record' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments", :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.reactions
        actual = json["data"].first["relationships"]["reactions"]["data"]
        expect(actual).to eq(expected)
      end
      it 'and getting the index returns the commentable record' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments", :headers => @auth_headers
        json = JSON.parse(response.body)
        expected = @comparable.first.commentable
        actual = json["data"].first["relationships"]["commentable"]
        expect(actual["data"]["id"].to_i).to eq(expected.id)
        expect(actual["data"]["type"]).to eq(expected.class.to_s.downcase)
      end
      it 'shows relevant resources' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments", :headers => @auth_headers
        
        json = JSON.parse(response.body)
        actual = json["data"].first["relationships"]
        expect(actual).to include("reactions")
        expect(actual).to include("commentable")
        expect(actual).to include("comment-replies")
        expect(actual).to include("member")
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
    context "GET subjects/:id/comments/:comment_id Comments#show" do
      before do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        @comparable.media.attach(io: File.open(@image_file), filename: @image_filename, content_type: @image_content_type)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "shows 200 status and matches comparable" do
        get "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :headers => @auth_headers

        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]

        expect(response).to have_http_status(200)
        expect(json["data"]["id"].to_i).to eq(@comparable.id)
        expect(actual["body"]).to eq(@comparable.body)
        expect(actual["edit"]).to eq(@comparable.edit)
        expect(actual["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual["member-id"]).to eq(@comparable.member_id)

      end
      it 'and it shows reactions, commentable, comment_replies, and member' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]
        expect(actual).to include("commentable")
        expect(actual["commentable"]).to include("data")

        expect(actual).to include("member")
        expect(actual["member"]).to include("data")

        expect(actual).to include("comment-replies")
        expect(actual["comment-replies"]).to include("data")

        expect(actual).to include("reactions")
        expect(actual["reactions"]).to include("data")
      end
      it 'it shows links in the attributes' do
        get "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]["links"]

        expect(actual).to include("self")
        expect(actual["self"]).to include(api_v1_comment_path(json["data"]["id"].to_i))

        expect(actual).to include("comment-replies")
        expect(actual["comment-replies"]).to include(api_v1_comment_comment_replys_path(json["data"]["id"].to_i))

        expect(actual).to include("member")
        expect(actual["member"]).to include(api_v1_member_path(json["data"]["attributes"]["member-id"].to_i))
      end
    end
    context "POST subjects/:id/comments Comments#create" do
      before do
       @comparable = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
       @create_request_params = {
            "attributes": {
              "body": @comparable.body,
              "commentable_type": @comparable.commentable_type,
              "commentable_id": @comparable.commentable_id,
              "member_id": @comparable.member_id,
              "media": @image_file
            }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status for principle route" do
        post "/v1/comments", :params => {:comment => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "200 status for subject nested route" do
        post "/v1/#{@subject_class}/#{@subject.id}/comments", :params => {:comment => @create_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it 'and it returns the json for the newly created comment' do
        post '/v1/comments', :params => {:comment => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        post_create_comparable = Comment.where(commentable_type: @comparable.commentable_type, commentable_id: @comparable.commentable_id, member_id: @comparable.member_id, body: @comparable.body).first
        expect(json["data"]["id"].to_i).to eq(post_create_comparable.id)
        expect(actual["body"]).to eq(@comparable.body)
        expect(actual["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual["member-id"]).to eq(@comparable.member_id)
        expect(actual["media"]).to eq(rails_blob_path(post_create_comparable.media))
      end
      it 'shows the relationships and links to them in the json package' do
        post '/v1/comments', :params => {:comment => @create_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("commentable")
        expect(actual).to include("reactions")
        expect(actual).to include("comment-replies")
        expect(actual).to include("member")

        expect(actual["commentable"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
    end
    context "PUT - PATCH subjects/:id/comments/:id Comments#update" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        update = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id )
        @update_put_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "commentable_type": @subject.class.to_s,
              "commentable_id": @subject.id,
              "member_id": @comparable.member_id,
              "body": update.body,
              "media" => @image_file
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body,
              "media" => @image_file
            }
          }
        }
      end
      it "#put 200 status with nested subject route" do
        put "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "#patch 200 status with nested subject route" do
        patch "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it "#put 200 status and matches the json for the putted comment" do
        put "/v1/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment][:attributes].as_json

        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual_attributes["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual_attributes["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it "#patch 200 status and can replace a single attribute and it returns the json for the patched comment" do
        patch "/v1/comments/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_patch_request_params[:comment][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual_attributes["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual_attributes["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it '#patch shows the relationships and links to them in the json package' do
        patch "/v1/comments/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("commentable")
        expect(actual).to include("reactions")
        expect(actual).to include("comment-replies")
        expect(actual).to include("member")

        expect(actual["commentable"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
      it '#put shows the relationships and links to them in the json package' do
        put "/v1/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        json = JSON.parse(response.body)
        actual = json["data"]["relationships"]

        expect(actual).to include("commentable")
        expect(actual).to include("reactions")
        expect(actual).to include("comment-replies")
        expect(actual).to include("member")

        expect(actual["commentable"]["data"]["id"].to_i).to eq(@subject.id)
        expect(actual["member"]["data"]["id"].to_i).to eq(@comparable.member_id)
      end
      it 'can patch a single media file' do
        file_upload_params = {:comment => {:attributes => {:media => @image_file}}}
        expect(@comparable.media.attached?).to_not eq(true)
        patch "/v1/comments/#{@comparable.id}", :params => file_upload_params, :headers => @auth_headers
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)["data"]["attributes"]["media"]
        expect(@comparable.reload.media.attached?).to eq(true)
        expect(rails_blob_path(@comparable.reload.media)).to eq(json)
      end
    end
    context "DELETE /comments/:id Comments#destroy" do
      before(:each) do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a comment via nested subject route" do
        delete_request_params = {:id => @comparable.id }
        delete "/v1/#{@subject_class}/#{@subject.id}/comments/#{@comparable.id}", :params => {comment: delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it "can sucessfully delete a comment" do
        delete_request_params = {:id => @comparable.id }
        delete "/v1/comments/#{@comparable.id}", :params => {comment: delete_request_params}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it 'returns 404 for missing content' do
        deleted_comparable_id = @comparable.id
        delete_request_params = {:id => deleted_comparable_id }
        Comment.find(deleted_comparable_id).destroy
        delete "/v1/comments/#{deleted_comparable_id}", :params => {comment: delete_request_params}, :headers => @auth_headers
        json = JSON.parse(response.body) 
        expect(json).to eq({})
        expect(response).to have_http_status(404)
      end
    end
    context "Unauthorize Inside Family ::" do
      before do
        @second_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now).member
      end
      context "PUT-PATCH /comments Comments#update :: Member 2 => Member 1 ::" do
        before(:each) do
          @auth_headers = @member.create_new_auth_token
          @update_subject = FactoryBot.create(:"#{@subject.class.to_s.downcase}", family_id: @member_family_id, member_id: @second_member.id)
          @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @second_member.id)
          @updates = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        end
        it "unable to #put update on another family member's comment" do
          unauthorized_update_put_request_params = {
            "id": @comparable[:id],
            "comment": {
              "id": @comparable[:id],
              "attributes": {
              "commentable_type": @subject.class.to_s,
              "commentable_id": @subject.id,
              "member_id": @updates[:member_id],
              "body": @updates[:body],
              "media": @image_file
              }
            }
          }

          put "/v1/comments/#{@comparable.id}", :params => unauthorized_update_put_request_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #patch update on another family member's comment" do
          unauthorized_patch_of_post_params = {
            "id": @comparable[:id],
            "comment": {
              "body": @updates[:body],
              "media": @image_file
            }
          }

          patch "/v1/comments/#{@comparable.id}", :params => unauthorized_patch_of_post_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #patch update on a protected field" do
          update_patch_request_unpermitted_params = {
            "id": @comparable[:id],
            "comment": {
              "id": @comparable[:id],
              "commentable_type": @update_subject.class.to_s,
              "commentable_id": @update_subject.id,
              "member_id": @updates[:member_id],
              "body": @updates[:body]
            }
          }
          patch "/v1/comments/#{@comparable.id}", :params => update_patch_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
        it "unable to #put update on a protected field" do
          update_put_request_unpermitted_params = {
            "id": @comparable[:id],
            "comment": {
              "id": @comparable[:id],
              "commentable_type": @update_subject.class.to_s,
              "commentable_id": @update_subject.id,
              "member_id": @updates[:member_id],
              "body": @updates[:body]
            }
          }
          put "/v1/comments/#{@comparable.id}", :params => update_put_request_unpermitted_params, :headers => @auth_headers
          expect(response).to have_http_status(403)
        end
      end
      context "DELETE /comments Comments#delete :: Member 2 => Member 1" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
        it "unable to delete on another family member's comment" do
          @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @second_member.id)
          delete_request_params = {comment: {:id => @comparable.id }}
          delete "/v1/comments/#{@comparable.id}", :params => delete_request_params, :headers => @auth_headers
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
      @normal_member = FactoryBot.create(:family_member, family_id: @family.id).member # normal user
      login_auth(@member) # login admin
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
      @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @normal_member.id)
      update = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
      @update_put_request_params = {
        "id": @comparable.id,
        "comment": {
          "id": @comparable.id,
          "attributes": {
            "commentable_type": @subject.class.to_s,
            "commentable_id": @subject.id,
            "member_id": @comparable.member_id,
            "body": update.body
          }
        }
      }
      @update_patch_request_params = {
        "id": @comparable.id,
        "comment": {
          "id": @comparable.id,
          "attributes": {
            "body": update.body,
            "media": @image_file
          }
        }
      }
    end
    context "PUT-PATCH /comments Comments#update" do
      it "able to #put update on another family member's comment" do
        put "/v1/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual_attributes["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual_attributes["media"]).to eq(expected["media"])
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
      it "able to #patch update on another family member's comment" do
        patch "/v1/comments/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expected = @update_put_request_params[:comment][:attributes].as_json
        
        json = JSON.parse(response.body)
        actual = json["data"]
        actual_attributes = json["data"]["attributes"]
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@comparable.id)
        expect(actual_attributes["body"]).to eq(expected["body"])
        expect(actual_attributes["edit"]).to eq(@comparable.edit)
        expect(actual_attributes["commentable-type"]).to eq(@comparable.commentable_type)
        expect(actual_attributes["commentable-id"]).to eq(@comparable.commentable_id)
        expect(actual_attributes["media"]).to eq(rails_blob_path(@comparable.reload.media))
        expect(actual_attributes["member-id"]).to eq(@comparable.member_id)
      end
    end
    context "DELETE /comments Comments#destroy" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can sucessfully delete a comment" do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @normal_member.id)
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/comments/#{@comparable.id}", :params => {comment: @delete_request_params}, :headers => @auth_headers
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
    context "GET /comments Comments#index" do
      # This only applys to Recipes as commentable because each recipe belongs to a member.
      # Hypothetically, you could have one user (family A and B) who is apart of two families where the
      # third user (member of family B) is unable to see first user's comment (family A).
      before do
        @index_subject = FactoryBot.create(:recipe, member_id: @join_member.id)
        @authorized_comparable = FactoryBot.create_list(:comment, 2, commentable_type: @index_subject.class.to_s, commentable_id: @index_subject.id, member_id: @authorized_member.id)
        @unauthorized_comparable = FactoryBot.create_list(:comment, 2, commentable_type: @index_subject.class.to_s, commentable_id: @index_subject.id, member_id: @unauthorized_member.id)
      end
      after(:each) do
        logout_auth(@member)
      end
      it "200 with nested subject and returns 2 comments for unauthorized_member" do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/comments/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(@unauthorized_comparable.pluck(:id)).to include(actual.first["id"].to_i)
        expect(@unauthorized_comparable.pluck(:id)).to include(actual.last["id"].to_i)
        expect(@authorized_comparable.pluck(:id)).to_not include(actual.first["id"].to_i)
        expect(@authorized_comparable.pluck(:id)).to_not include(actual.last["id"].to_i)
        expect(actual.count).to eq(2)
        expect(response).to have_http_status(200)
      end
      it "200 with nested subject and returns 2 comments for authorized_member" do
        login_auth(@authorized_member) # @member = @authorized_member
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/comments/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        expect(@authorized_comparable.pluck(:id)).to include(actual.first["id"].to_i)
        expect(@authorized_comparable.pluck(:id)).to include(actual.last["id"].to_i)
        expect(@unauthorized_comparable.pluck(:id)).to_not include(actual.first["id"].to_i)
        expect(@unauthorized_comparable.pluck(:id)).to_not include(actual.last["id"].to_i)
        expect(actual.count).to eq(2)
        expect(response).to have_http_status(200)
      end
      it "200 with nested subject and returns 4 comments for join_member" do
        login_auth(@join_member) # @member = @join_member
        @auth_headers = @member.create_new_auth_token
        get "/v1/#{@index_subject.class.to_s.pluralize.downcase}/#{@index_subject.id}/comments/", :headers => @auth_headers
        json = JSON.parse(response.body) 
        actual = json["data"]
        actual_ids = []
        actual.pluck("id").each {|id| actual_ids << id.to_i}
        comparable_ids = @authorized_comparable.pluck(:id) + @unauthorized_comparable.pluck(:id)
        expect(actual_ids.sort).to eq(comparable_ids.sort)
        expect(actual.count).to eq(4)
        expect(response).to have_http_status(200)
      end
    end
    context "GET /comments Comments#show" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 status code on unauthorized access" do
        get "/v1/comments/#{@comparable.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "POST /comments Comments#create" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id)
        @create_request_params = {
          "comment": {
            "attributes": {
              "body": @comparable.body,
              "commentable_type": @comparable.commentable_type,
              "commentable_id": @comparable.commentable_id,
              "member_id": @comparable.member_id,
              "media": @image_file
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "unable to create a comment in another family" do
        post "/v1/comments", :params => @create_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "PUT-PATCH /comments Comments#update" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id)
        update = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @member.id )
        @update_put_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "commentable_type": @subject.class.to_s,
              "commentable_id": @subject.id,
              "member_id": @comparable.member_id,
              "body": update.body
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body,
              "media": @image_file
            }
          }
        }
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized update put" do
        put "/v1/comments/#{@comparable.id}", :params => @update_put_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
      it 'returns 403 error for an unauthorized update patch' do
        patch "/v1/comments/#{@comparable.id}", :params => @update_patch_request_params, :headers => @auth_headers
        expect(response).to have_http_status(403)
        expect(ActiveStorage::Attachment.all).to be_empty
      end
    end
    context "DELETE /comments Comments#destroy" do
      before do
        login_auth(@unauthorized_member) # @member = @unauthorized_member 
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "returns 403 error for an unauthorized attempt to delete" do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id)
        @delete_request_params = {:id => @comparable.id }

        delete "/v1/comments/#{@comparable.id}", :params => {comment: @delete_request_params}, :headers => @auth_headers
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
      @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id)
    end
    context "GET /comments Comments#index" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/#{@subject.class.to_s.downcase.pluralize}/#{@subject.id}/comments"
        expect(response).to have_http_status(401)
      end
    end
    context "GET /comments Comments#show" do
      it "returns a 401 error saying they are not authenticated" do
        get "/v1/comments/#{@comparable.id}"
        expect(response).to have_http_status(401)
      end
    end
    context "POST /comments Comments#create" do
      it "returns a 401 error saying they are not authenticated" do
        comparable_for_create = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: nil)
        @create_request_params = {
          "comment": {
            "attributes": {
              "body": comparable_for_create.body,
              "commentable_type": comparable_for_create.commentable_type,
              "commentable_id": comparable_for_create.commentable_id,
              "member_id": comparable_for_create.member_id
            }
          }
        }
        post "/v1/comments", :params => @comparable_for_create
        expect(response).to have_http_status(401)
      end
    end
    context "PUT-PATCH /comments Comments#update" do
      before do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id )
        update = FactoryBot.build(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: nil)
        @update_put_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body,
              "commentable_type": update.commentable_type,
              "commentable_id": update.commentable_id,
              "member_id": update.member_id
            }
          }
        }
        @update_patch_request_params = {
          "id": @comparable.id,
          "comment": {
            "id": @comparable.id,
            "attributes": {
              "body": update.body
            }
          }
        }
      end
      it "#put returns a 401 error saying they are not authenticated" do
        put "/v1/comments/#{@comparable.id}", :params => @update_put_request_params
        expect(response).to have_http_status(401)
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        patch "/v1/comments/#{@comparable.id}", :params => @update_patch_request_params
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /comments Comments#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        @comparable = FactoryBot.create(:comment, commentable_type: @subject.class.to_s, commentable_id: @subject.id, member_id: @authorized_member.id )
        @delete_request_params = {:id => @comparable.id }
        delete "/v1/comments/#{@comparable.id}", :params => @delete_request_params
        expect(response).to have_http_status(401)
      end
    end
  end # Unknown User Describe


end
