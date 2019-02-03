require 'rails_helper'
# Note: When "record" is mentioned in relation to a notification
# that is referring to the record found via notifiable_type and notifiable_id.
RSpec.describe "Notifications", type: :request do
  
  describe ':: Members / Same Family ::' do
    before do
      @family = FactoryBot.create(:family)
      @family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @member = @family_member.member
      @commenter_family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @commenter = @commenter_family_member.member
      login_auth(@member)
    end
    context "GET /v1/notifications Notifications#unviewed" do
      before(:each) do
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)
        @auth_headers = @member.create_new_auth_token
        @comparable_notifications = []
        @comparable_children.each {|child| @comparable_notifications << child.notifications.first}
      end
      it '200 and schema matches' do
        get "/v1/notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(response).to have_http_status(200)
        expect(@comparable_notifications.pluck(:id)).to include(json["data"].first["id"].to_i)
        expect(json["data"].first["type"]).to eq("notifications")
        expect(@comparable_notifications.pluck(:id)).to include(json["data"].second["id"].to_i)
        expect(json["data"].second["type"]).to eq("notifications")
        
        actual = json["data"].first
        expect(actual).to include("id")
        expect(actual).to include("type")
        
        expected_attributes = ["notifiable-type", "notifiable-id", "member-id", "mentioned", "viewed", "created-at", "updated-at"]
        actual_attributes = json["data"].first["attributes"].keys
        expect(actual_attributes).to eq(expected_attributes)

        expected_relationships = ["notifiable", "member"]
        json["data"].first["relationships"].each do |relationship|
          expect(expected_relationships).to include(relationship[0])
          expect(relationship[1]["data"]).to include("id")
          expect(relationship[1]["data"]).to include("type")
        end
        expect(json["data"].first["relationships"]["member"]["links"]).to include("self")
      end
      it 'should return just unviewed notifications' do
        view_array = @comparable_notifications.pluck(:viewed)
        for i in 0..view_array.length-1
          expect(view_array[i]).to eq(false)
        end
        get "/v1/notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(response).to have_http_status(200)
        # Refresh viewed_array to confirm change from false to true.
        viewed_array = Notification.find(@comparable_notifications.pluck(:id)).pluck(:viewed)
        actual_array = []
        json["data"].each {|record| actual_array  << record["attributes"]["viewed"]}

        expect(viewed_array.length).to eq(actual_array.length)
        for i in 0..viewed_array.length-1
          expect(actual_array[i]).to eq(false) # Response should be false.
          expect(viewed_array[i]).to eq(true) # Record should be marked true after sent.
        end
      end
    end
    context "GET /all_notifications Notifications#all" do
      before(:each) do
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)
        @auth_headers = @member.create_new_auth_token
        @comparable_notifications = []
        @comparable_children.each {|child| @comparable_notifications << child.notifications.first}
        @comparable_notifications.last.update_attributes(viewed: true)
      end
      it '200 and schema matches' do
        get "/v1/all_notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(response).to have_http_status(200)
        expect(@comparable_notifications.pluck(:id)).to include(json["data"].first["id"].to_i)
        expect(json["data"].first["type"]).to eq("notifications")
        expect(@comparable_notifications.pluck(:id)).to include(json["data"].second["id"].to_i)
        expect(json["data"].second["type"]).to eq("notifications")
        
        actual = json["data"].first
        expect(actual).to include("id")
        expect(actual).to include("type")
        
        expected_attributes = ["notifiable-type", "notifiable-id", "member-id", "mentioned", "viewed", "created-at", "updated-at"]
        actual_attributes = json["data"].first["attributes"].keys
        expect(actual_attributes).to eq(expected_attributes)

        expected_relationships = ["notifiable", "member"]
        json["data"].first["relationships"].each do |relationship|
          expect(expected_relationships).to include(relationship[0])
          expect(relationship[1]["data"]).to include("id")
          expect(relationship[1]["data"]).to include("type")
        end
        expect(json["data"].first["relationships"]["member"]["links"]).to include("self")
      end
      it 'should return viewed and unviewed notifications' do
        get "/v1/all_notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(response).to have_http_status(200)
        # Refresh viewed_array to confirm change from false to true.
        viewed_array = Notification.find(@comparable_notifications.pluck(:id)).pluck(:viewed)
        actual_array = []
        json["data"].each {|record| actual_array  << record["attributes"]["viewed"]}
        expect(actual_array[0]).to eq(false) # First Response should be false.
        expect(actual_array[1]).to eq(true) # Second Response should be true.
        expect(viewed_array.length).to eq(actual_array.length)
        for i in 0..viewed_array.length-1
          expect(viewed_array[i]).to eq(true) # Record should be marked false after sent.
        end
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Unauthorized to Other Users ::' do
    before do
      @family = FactoryBot.create(:family)
      @family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @member = @family_member.member
      @commenter_family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @commenter = @commenter_family_member.member
    end
    context "GET /v1/notifications Notifications#unviewed" do
      before(:each) do
        login_auth(@member) # @member = @member
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        logout_auth(@member) # @member = nil
        login_auth(@commenter) # @member = @commenter
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)

        @auth_headers = @member.create_new_auth_token
        @comparable_notifications = []
        @comparable_children.each {|child| @comparable_notifications << child.notifications.first}
      end
      it 'should return an empty array notifications' do
        get "/v1/notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(json).to eq({"data"=>[]})
        expect(response).to have_http_status(200)
      end
    end
    context "GET /all_notifications Notifications#all" do
      before(:each) do
        login_auth(@member) # @member = @member
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        logout_auth(@member) # @member = nil
        login_auth(@commenter) # @member = @commenter
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)
        
        @auth_headers = @member.create_new_auth_token
        @comparable_notifications = []
        @comparable_children.each {|child| @comparable_notifications << child.notifications.first}
        @comparable_notifications.last.update_attributes(viewed: true)
      end
      it 'should return an empty array notifications' do
        get "/v1/all_notifications", :headers => @auth_headers
        json = JSON.parse(response.body)
        expect(json).to eq({"data"=>[]})
        expect(response).to have_http_status(200)
      end
    end
  end # Members / Unauthorized to Family Describe
  
  describe ':: Unauthorized to Unknown User ::' do
    before do
      @family = FactoryBot.create(:family)
      @family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @member = @family_member.member
      @commenter_family_member = FactoryBot.create(:family_member, family_id: @family.id)
      @commenter = @commenter_family_member.member
    end
    context "GET /v1/notifications Notifications#unviewed" do
      before(:each) do
        login_auth(@member) # @member = @member
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        logout_auth(@member) # @member = nil
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)
      end
      it 'should return an empty array notifications' do
        get "/v1/notifications"
        json = JSON.parse(response.body)
        expect(response).to have_http_status(401)
      end
    end
    context "GET /all_notifications Notifications#all" do
      before(:each) do
        login_auth(@member) # @member = @member
        @comparable = FactoryBot.create(:post, family_id: @family.id, member_id: @member.id)
        logout_auth(@member) # @member = nil
        @comparable_children = FactoryBot.create_list(:comment, 2, commentable_type: "Post", commentable_id: @comparable.id, member_id: @commenter.id)
        @comparable_notifications = []
        @comparable_children.each {|child| @comparable_notifications << child.notifications.first}
        @comparable_notifications.last.update_attributes(viewed: true)
      end
      it 'should return an empty array notifications' do
        get "/v1/all_notifications"
        json = JSON.parse(response.body)
        expect(response).to have_http_status(401)
      end
    end

  end # Unknown User Describe
  
end # notification RSpec
