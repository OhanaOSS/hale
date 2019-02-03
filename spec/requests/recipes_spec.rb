require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let(:image_file){ fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/img.jpg', 'img/jpg') }
  let(:image_filename){'img.jpg'}
  let(:image_content_type){'image/jpg'}
  describe ':: Members / Same Family ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
      second_family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
      @second_member = second_family_member.member
      @member = family_member.member

      # Recipe Formatter
      @comparables_array = []
        5.times do
          # Starting to build a recipe
          @create_tags_list = [
            {"title": "tasty", "description": Faker::Lorem.sentence},{"title": "vegan", "description": Faker::Lorem.sentence},{"title": "italian", "description": "Cultural food deriving from italy", "mature": true}
          ]
          ingredient_list = []
          rand(6..9).times do
            item = Faker::Food.ingredient
            ingredient_list << item if !item.nil?
          end
          prep_step = []
          cooking_step = []
          post_step = []
          # Building the steps of the test recipe
          6.times do |i|
            prep = ["stir", "masage", "whip",]
            cooking = ["bake", "saute", "grill"]
            post = ["combine", "toss"]
            # Prep
            if i <= 1
              prep_step_task = "Take #{ingredient_list[i]} and #{prep[i]} it till it's you think it's ready."
              prep_step_array_item = {:instruction => prep_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => [ingredient_list[i]]}
              prep_step.push(prep_step_array_item)
            elsif i >= 2 && i <= 4
              num = rand(0..1)
              cooking_step_task = "Take #{ingredient_list[i]} and combine it with #{ingredient_list[num]} and #{cooking[i]} it till it's done."
              cooking_step_array_item = {:instruction => cooking_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => [ingredient_list[i], ingredient_list[num]]}
              cooking_step.push(cooking_step_array_item)
            else
              post_step_task = "Take #{ingredient_list.slice(0..1).join(', ')} and #{ingredient_list[2]} then #{post.sample} it with #{ingredient_list[-1]}."
              post_step_array_item = {:instruction => post_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => ingredient_list[0..2].push(ingredient_list[-1])}
              post_step.push(post_step_array_item)
            end
          end
          steps = {"preparation" => prep_step, "cooking" => cooking_step, "post_cooking" => post_step}
          # Formatting Recipe
          @new_recipe = FactoryBot.build(:recipe, steps: steps, member_id: @member.id, ingredients_list: ingredient_list)
          @subject_build = FactoryBot.build(:recipe, steps: steps, member_id: @member.id, ingredients_list: ingredient_list)
          # Saving Recipe
          if @new_recipe.save
            # If sucessful create shovel recipe id to recipe list array
            @comparables_array << @new_recipe.id
            @create_tags_list.each do |tag|
              tag_obj = FactoryBot.create(:tag, title: tag[:title], description: tag[:description] )
              FactoryBot.create(:recipe_tag, tag_id: tag_obj.id, recipe_id: @new_recipe.id )
            end
            @new_recipe.ingredients_list.each do |ingredient|
              ingredient_obj = FactoryBot.create(:ingredient, title: ingredient )
              FactoryBot.create(:recipe_ingredient, ingredient_id: ingredient_obj.id, recipe_id: @new_recipe.id )
            end
            FactoryBot.create(:reaction, member_id: [@second_member.id, @member.id].sample, interaction_type: "Recipe", interaction_id: @new_recipe.id)

          end
        end
        # Recipe List for Comparsions
        @comparables = Recipe.where(id: @comparables_array)
        @comparable = @comparables.first
        @media_attached_comparable = @comparable
        @media_attached_comparable.media.attach(io: File.open(image_file), filename: image_filename, content_type: image_content_type)
    end
    context "GET /recipes Recipes#index" do
      before do
        login_auth(@member)
      end
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      
      it "200 status with correct json schema" do
        get '/v1/recipes', :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual = json
        expected = @comparables
        actual_record = nil
        json.each {|data| actual_record = data if data["attributes"]["media"] == rails_blob_path(@media_attached_comparable.media)}
        expected_record = @comparables.where(id: actual_record["id"].to_i).first
        expect(response).to have_http_status(200)

        expect(actual_record["attributes"]["title"]).to eq(expected_record.title)
        expect(actual_record["attributes"]["description"]).to eq(expected_record.description)
        expect(actual_record["attributes"]["member-id"]).to eq(expected_record.member_id)
        expect(actual_record["attributes"]["media"]).to eq(rails_blob_path(@media_attached_comparable.media))
        expect(actual_record["attributes"]["tags-list"]).to eq(expected_record.tags_list)
        expect(actual_record["attributes"]["ingredients-list"]).to eq(expected_record.ingredients_list)

        actual_steps = actual_record["attributes"]["steps"]
        expect(actual_steps).to include("preparation")
        expect(actual_steps).to include("cooking")
        expect(actual_steps).to include("post-cooking")

        actual_steps_example = actual_record["attributes"]["steps"]["preparation"].first
        expected_example = expected_record.steps["preparation"].first
        expect(actual_steps_example["instruction"]).to eq(expected_example["instruction"])
        expect(actual_steps_example["time-length"]).to eq(expected_example["time_length"])
        expect(actual_steps_example["ingredients"]).to eq(expected_example["ingredients"])

      end
      it 'and can get all of the records available to the Member\'s policy via index' do
        non_family_recipe = FactoryBot.create(:recipe, member_id: FactoryBot.create(:family_member).member.id)
        get '/v1/recipes', :headers => @auth_headers
        expect(response).to have_http_status(200)
        actual = JSON.parse(response.body)["data"]
        actual_count = JSON.parse(response.body)["data"].count
        authorized_family_member_member_ids = FamilyMember.where(family_id: @family.id).pluck(:member_id).uniq
        expected_count = Recipe.where(member_id: authorized_family_member_member_ids).count
        expect(actual_count).to eq(expected_count)
        actual.each do |recipe|
          expect(recipe["id"]).to_not eq(non_family_recipe.id)
        end
      end
      it 'shows the relationships' do
        get '/v1/recipes', :headers => @auth_headers
        actual_record = JSON.parse(response.body)["data"].first["relationships"]
        expect(response).to have_http_status(200)
        expect(actual_record).to include("reactions")
        expect(actual_record).to include("tags")
        expect(actual_record).to include("ingredients")
        expect(actual_record).to include("member")
      end
    end
    context "POST /recipes Recipes#create" do
      before(:each) do
        create_tags_list = [
          {"title": "foobar"},{"title": "foobaz", "description": Faker::Lorem.sentence},{"title": "italian", "description": "Cultural food deriving from italy", "mature": true}
        ]
        ingredient_list = []
        rand(6..9).times do
          item = Faker::Food.ingredient
          ingredient_list << item if !item.nil?
        end
        prep_step = []
        cooking_step = []
        post_step = []

        6.times do |i|
          prep = ["foobar","stir", "masage", "whip",]
          cooking = ["bake", "saute", "grill"]
          post = ["combine", "toss"]
          # Prep
          if i <= 1
            prep_step_task = "Take #{ingredient_list[i]} and #{prep[i]} it till it's you think it's ready."
            prep_step_array_item = {:instruction => prep_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => [ingredient_list[i]]}
            prep_step.push(prep_step_array_item)
          elsif i >= 2 && i <= 4
            num = rand(0..1)
            cooking_step_task = "Take #{ingredient_list[i]} and combine it with #{ingredient_list[num]} and #{cooking[i]} it till it's done."
            cooking_step_array_item = {:instruction => cooking_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => [ingredient_list[i], ingredient_list[num]]}
            cooking_step.push(cooking_step_array_item)
          else
            post_step_task = "Take #{ingredient_list.slice(0..1).join(', ')} and #{ingredient_list[2]} then #{post.sample} it with #{ingredient_list[-1]}."
            post_step_array_item = {:instruction => post_step_task, :time_length => "#{rand(1..90)} minutes", :ingredients => ingredient_list[0..2].push(ingredient_list[-1])}
            post_step.push(post_step_array_item)
          end
        end
        steps = {"preparation" => prep_step, "cooking" => cooking_step, "post_cooking" => post_step}

        @recipe = FactoryBot.build(:recipe, steps: steps, member_id: @member.id, ingredients_list: ingredient_list)
        @create_request_params = {
          "attributes": {
            "title": @recipe.title,
            "description": @recipe.description,
            "member_id": @recipe.member_id,
            "ingredients_list": @recipe.ingredients_list, 
            "steps": steps, 
            "tags_list": create_tags_list,
            "media": image_file
          }
        }
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status of correct type" do
        post '/v1/recipes', :params => {recipe: @create_request_params}, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(response).to have_http_status(200)
        expect(actual["type"]).to eq("recipe")
        expect(actual).to include("id")
      end
      it 'and it returns the json for the newly created post following schema' do
        post '/v1/recipes', :params => {recipe: @create_request_params}, :headers => @auth_headers
        actual_id = JSON.parse(response.body)["data"]["id"].to_i
        actual = JSON.parse(response.body)["data"]["attributes"]
        expected = @create_request_params[:attributes]

        expect(response).to have_http_status(200)
        expect(actual["title"]).to eq(expected[:title])
        expect(actual["description"]).to eq(expected[:description])
        expect(actual["member-id"]).to eq(expected[:member_id])
        expect(actual["media"]).to eq(rails_blob_path(Recipe.find(actual_id).media))
        expect(actual["tags-list"].first).to_not eq(expected[:tags_list].pluck(:title).first)
        expect(actual["tags-list"].second_to_last.downcase).to eq(expected[:tags_list].pluck(:title).second_to_last.downcase)
        expect(actual["tags-list"].last.downcase).to eq(expected[:tags_list].pluck(:title).last.downcase)
        expect(actual["ingredients-list"]).to eq(expected[:ingredients_list])

        actual_steps = actual["steps"]
        expect(actual_steps).to include("preparation")
        expect(actual_steps).to include("cooking")
        expect(actual_steps).to include("post-cooking")

        actual_steps_example = actual["steps"]["preparation"].first
        expected_example = @create_request_params[:attributes][:steps]["preparation"].first
        expect(actual_steps_example["instruction"]).to eq(expected_example[:instruction])
        expect(actual_steps_example["time-length"]).to eq(expected_example[:time_length])
        expect(actual_steps_example["ingredients"]).to eq(expected_example[:ingredients])
      end
      it 'shows the relationships and links to them in the json package' do
        post '/v1/recipes', :params => {recipe: @create_request_params}, :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        actual_relationships = actual["relationships"]
        actual_links = actual["links"]
        expect(response).to have_http_status(200)
        expect(actual_relationships).to include("member")
        expect(actual_relationships).to include("tags")
        expect(actual_relationships).to include("ingredients")

        expect(actual_links["self"]).to eq(Rails.application.routes.url_helpers.api_v1_recipes_path(id: actual["id"]))
      end
    end
    context "GET /recipes Recipes#show" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 status with correct json schema" do
        get "/v1/recipes/#{@comparable.id}", :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_record = json["attributes"]
        expected_record = @comparable
        expect(response).to have_http_status(200)
        expect(json["id"].to_i).to eq(expected_record.id)
        expect(json["type"]).to eq(expected_record.class.to_s.downcase)
        expect(actual_record["title"]).to eq(expected_record.title)
        expect(actual_record["description"]).to eq(expected_record.description)
        expect(actual_record["member-id"]).to eq(expected_record.member_id)
        expect(actual_record["media"]).to eq(rails_blob_path(expected_record.media))
        expect(actual_record["tags-list"]).to eq(expected_record.tags_list)
        expect(actual_record["ingredients-list"]).to eq(expected_record.ingredients_list)

        actual_steps = actual_record["steps"]
        expect(actual_steps).to include("preparation")
        expect(actual_steps).to include("cooking")
        expect(actual_steps).to include("post-cooking")

        actual_steps_example = actual_record["steps"]["preparation"].first
        expected_example = expected_record.steps["preparation"].first
        expect(actual_steps_example["instruction"]).to eq(expected_example["instruction"])
        expect(actual_steps_example["time-length"]).to eq(expected_example["time_length"])
        expect(actual_steps_example["ingredients"]).to eq(expected_example["ingredients"])
      end
      it 'reactions relationship link' do
        get "/v1/recipes/#{@comparable.id}", :headers => @auth_headers
        expect(response).to have_http_status(200)
        actual_recipe = JSON.parse(response.body)["data"]
        reaction_link = actual_recipe["relationships"]["reactions"]["links"]["related"]
        expect(reaction_link).to include(api_v1_recipe_reactions_path(@comparable.id))
      end
      it 'shows the relationships' do
        get '/v1/recipes', :headers => @auth_headers
        actual_record = JSON.parse(response.body)["data"].first["relationships"]
        expect(response).to have_http_status(200)
        expect(actual_record).to include("reactions")
        expect(actual_record).to include("tags")
        expect(actual_record).to include("ingredients")
        expect(actual_record).to include("member")
      end
    end
    context "PUT-PATCH /recipes Recipes#update" do
      before(:each) do
        @comparable = FactoryBot.create(:recipe, member_id: @member.id)
        @recipe = FactoryBot.build(:recipe, member_id: @member.id)
        @update_params = {
          "attributes": {
            "title": @recipe.title,
            "description": @recipe.description,
            "ingredients_list": @recipe.ingredients_list, 
            "steps": @recipe.steps
          }
        }
        @auth_headers = @member.create_new_auth_token
      end
      it "#patch 200 status with changes" do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_record = json["attributes"]
        expected_record = @update_params[:attributes]
        expect(response).to have_http_status(200)
        expect(actual_record["title"]).to eq(expected_record[:title])
        expect(actual_record["description"]).to eq(expected_record[:description])
        expect(actual_record["ingredients-list"]).to eq(expected_record[:ingredients_list])
      end
      it '#patch reactions relationship link' do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
        actual_recipe = JSON.parse(response.body)["data"]
        reaction_link = actual_recipe["relationships"]["reactions"]["links"]["related"]
        expect(reaction_link).to include(api_v1_recipe_reactions_path(@comparable.id))
      end
      it '#patch shows the relationships' do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        actual_record = JSON.parse(response.body)["data"]["relationships"]
        expect(response).to have_http_status(200)
        expect(actual_record).to include("reactions")
        expect(actual_record).to include("tags")
        expect(actual_record).to include("ingredients")
        expect(actual_record).to include("member")
      end
      it "#put 200 status with changes" do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_record = json["attributes"]
        expected_record = @update_params[:attributes]
        expect(response).to have_http_status(200)
        expect(actual_record["title"]).to eq(expected_record[:title])
        expect(actual_record["description"]).to eq(expected_record[:description])
        expect(actual_record["ingredients-list"]).to eq(expected_record[:ingredients_list])
      end
      it '#put reactions relationship link' do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(200)
        actual_recipe = JSON.parse(response.body)["data"]
        reaction_link = actual_recipe["relationships"]["reactions"]["links"]["related"]
        expect(reaction_link).to include(api_v1_recipe_reactions_path(@comparable.id))
      end
      it '#put shows the relationships' do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        actual_record = JSON.parse(response.body)["data"]["relationships"]
        expect(response).to have_http_status(200)
        expect(actual_record).to include("reactions")
        expect(actual_record).to include("tags")
        expect(actual_record).to include("ingredients")
        expect(actual_record).to include("member")
      end
      it '#patch able to upload an image' do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => {:attributes => {:media => image_file}}}, :headers => @auth_headers
        media = JSON.parse(response.body)["data"]["attributes"]["media"]
        expect(response).to have_http_status(200)
        expect(media).to eq(rails_blob_path(@comparable.reload.media))
      end
      it "#put able to upload an image" do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params.merge!(:attributes => {:media => image_file})}, :headers => @auth_headers
        media = JSON.parse(response.body)["data"]["attributes"]["media"]
        expect(response).to have_http_status(200)
        expect(media).to eq(rails_blob_path(@comparable.reload.media))
      end
      it "unable to #put on another family member's recipe" do
        auth_comparable = FactoryBot.create(:recipe, member_id: @second_member.id)
        put "/v1/recipes/#{auth_comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it "unable to #patch on another family member's recipe" do
        auth_comparable = FactoryBot.create(:recipe, member_id: @second_member.id)
        patch "/v1/recipes/#{auth_comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "DELETE /recipes Recipes#destroy" do
      before(:each) do
        @comparable = FactoryBot.create(:recipe, member_id: @member.id)
        @auth_headers = @member.create_new_auth_token
      end
      it 'can sucessfully delete a post' do
        delete "/v1/recipes/#{@comparable.id}", :params => {:id => @comparable.id}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
      it 'returns 404 for missing content' do
        Recipe.destroy(@comparable.id)
        delete "/v1/recipes/#{@comparable.id}", :params => {:id => @comparable.id}, :headers => @auth_headers
        expect(response).to have_http_status(404)
      end
      it "unable to delete on another family member's recipe" do
        auth_comparable = FactoryBot.create(:recipe, member_id: @second_member.id)
        delete "/v1/recipes/#{auth_comparable.id}", :params => {:id => auth_comparable.id}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "GET /recipes Recipes#search" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 request" do
        query_value = @comparables.first.tags_list.first
        get '/v1/recipes/search', params: {filter: {:type => :tag, :query => query_value}}, headers: @auth_headers
        expect(response).to have_http_status(200)
      end
      it "returns unprocessible entity if type doesn't match" do
        query_value = @comparables.first.tags_list.first
        get '/v1/recipes/search', params: {filter: {:type => :name, :query => query_value}}, headers: @auth_headers
        expect(response).to have_http_status(:bad_request)
      end
      it "can return a recipe by tag title match" do
        query_value = @comparables.second.tags_list.first
        get '/v1/recipes/search', params: {filter: {:type => :tag, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_tag_list = json.first["attributes"]["tags-list"]
        actual_tags = json.first["relationships"]["tags"]["data"]
        expect(response).to have_http_status(200)

        query_tag_match = 0
        actual_tags.each do |data|
          tag_actual_title = Tag.find(data["id"].to_i).title
          query_tag_match = query_tag_match + 1 if tag_actual_title === query_value
        end
        expect(query_tag_match).to be >= 1
        expect(actual_tag_list).to include(query_value)
      end
      it "can return a recipe by tag description partial" do
        selected_tag = @comparables.second.tags.order("id ASC").first
        query_value = selected_tag.description.split(" ")[1..3].join(" ")
        get '/v1/recipes/search', params: {filter: {:type => :tag, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_tag_list = json.first["attributes"]["tags-list"]
        actual_tags = json.first["relationships"]["tags"]["data"]
        expect(response).to have_http_status(200)
        expect(selected_tag.description).to include(query_value) # self validate
        
        query_tag_match = 0
        expected_tag_id = nil
        actual_tags.each do |data|
          tag_actual_description = Tag.find(data["id"].to_i).description
          next if tag_actual_description.nil? # might be nil in real world cases.
          query_tag_match = query_tag_match + 1 if tag_actual_description.include?(query_value)
          expected_tag_id = data["id"].to_i if tag_actual_description.include?(query_value)
        end
        expect(query_tag_match).to be >= 1
        expect(expected_tag_id).to eq(selected_tag.id)
        expect(actual_tag_list).to include(selected_tag.title)
      end
      it "can return a recipe by recipe title match" do
        query_value = @comparables.third.title
        get '/v1/recipes/search', params: {filter: {:type => :recipe, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_title = json.first["attributes"]["title"]
        expect(response).to have_http_status(200)
        expect(actual_title).to eq(query_value)
      end
      it "can return a recipe by recipe description partial" do
        selected_recipe = @comparables.third
        query_value = selected_recipe.description.split(" ")[1..3].join(" ")
        get '/v1/recipes/search', params: {filter: {:type => :recipe, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_description = json.first["attributes"]["description"]
        expect(response).to have_http_status(200)
        expect(selected_recipe.description).to include(query_value) # self validate
        expect(actual_description).to include(query_value)
      end
      it "can return a recipe by ingredient title match" do
        query_value = @comparables.fourth.ingredients_list.first
        get '/v1/recipes/search', params: {filter: {:type => :ingredient, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_ingredient_list = json.first["attributes"]["ingredients-list"]
        actual_ingredients = json.first["relationships"]["ingredients"]["data"]
        expect(response).to have_http_status(200)

        query_ingredient_match = 0
        actual_ingredients.each do |data|
          ingredient_actual_title = Ingredient.find(data["id"].to_i).title
          query_ingredient_match = query_ingredient_match + 1 if ingredient_actual_title === query_value
        end
        expect(query_ingredient_match).to be >= 1
        expect(actual_ingredient_list).to include(query_value)
      end
    end
  end # Members / Same Family Describe
  
  describe ':: Members / Same Family - Admin Role ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now, user_role: "admin")
      second_family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
      @second_member = second_family_member.member
      @member = family_member.member
      login_auth(@member)
    end
    before(:each) do
      @auth_headers = @member.create_new_auth_token
    end
    context "PUT-PATCH /recipes Recipes#update" do
      before(:each) do
        @comparable = FactoryBot.create(:recipe, member_id: @second_member.id)
        @recipe = FactoryBot.build(:recipe, member_id: @member.id)
        @update_params = {
          "attributes": {
            "title": @recipe.title,
            "description": @recipe.description,
            "ingredients_list": @recipe.ingredients_list,
            "media": image_file
          }
        }
        @auth_headers = @member.create_new_auth_token
      end
      it "able to #patch update on another family member's recipe" do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_record = json["attributes"]
        expected_record = @update_params[:attributes]
        expect(response).to have_http_status(200)
        expect(actual_record["title"]).to eq(expected_record[:title])
        expect(actual_record["description"]).to eq(expected_record[:description])
        expect(actual_record["ingredients-list"]).to eq(expected_record[:ingredients_list])
        expect(actual_record["media"]).to eq(rails_blob_path(Recipe.find(@comparable.id).media))
      end
      it "able to #put update on another family member's recipe" do
        put "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        json = JSON.parse(response.body)["data"]
        actual_record = json["attributes"]
        expected_record = @update_params[:attributes]
        expect(response).to have_http_status(200)
        expect(actual_record["title"]).to eq(expected_record[:title])
        expect(actual_record["description"]).to eq(expected_record[:description])
        expect(actual_record["ingredients-list"]).to eq(expected_record[:ingredients_list])
        expect(actual_record["media"]).to eq(rails_blob_path(Recipe.find(@comparable.id).media))
      end
    end
    context "DELETE /recipes Recipes#destroy" do
      before(:each) do
        @comparable = FactoryBot.create(:recipe, member_id: @second_member.id)
        @auth_headers = @member.create_new_auth_token
      end
      it "able to delete on another family member's recipe" do
        delete "/v1/recipes/#{@comparable.id}", :params => {:id => @comparable.id}, :headers => @auth_headers
        expect(response).to have_http_status(204)
      end
    end
  end # Members / Same Family - Admin Role Describe
  
  describe ':: Members / Unauthorized to Family ::' do
    before do
      @family = FactoryBot.create(:family)
      family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
      second_family_member = FactoryBot.create(:family_member, family_id: @family.id, authorized_at: DateTime.now)
      @auth_second_member = second_family_member.member
      @auth_member = family_member.member
      @family_recipe = FactoryBot.create_list(:recipe, 5, title: "foobar", member_id: [@auth_member.id, @auth_second_member.id].sample)

      non_family = FactoryBot.create(:family_member, authorized_at: DateTime.now)
      @member = non_family.member
      @non_family_recipe = FactoryBot.create(:recipe, title: "foobar", member_id: @member.id)
      login_auth(@member)
    end
    context "GET /recipes Recipes#index" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 scoped to their own Recipes" do
        get '/v1/recipes', :headers => @auth_headers
        actual = JSON.parse(response.body)["data"]
        expect(response).to have_http_status(200)
        expect(actual.count).to eq(1)
      end
    end
    context "GET /recipes Recipes#show" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "200 for non_family recipe" do
        get "/v1/recipes/#{@non_family_recipe.id}", :headers => @auth_headers
        expect(response).to have_http_status(200)
      end
      it '403 for family_recipe' do
        get "/v1/recipes/#{@family_recipe.first.id}", :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "GET /recipes Recipes#search" do
      before(:each) do
        @auth_headers = @member.create_new_auth_token
      end
      it "can return a recipe by recipe title match that is scoped" do
        query_value = @family_recipe.first.title
        get '/v1/recipes/search', params: {filter: {:type => :recipe, :query => query_value}}, headers: @auth_headers
        json = JSON.parse(response.body)["data"]
        actual = json.first
        actual_title = actual["attributes"]["title"]
        expect(Recipe.all.count).to be >= json.count
        expect(response).to have_http_status(200)
        expect(actual["id"].to_i).to eq(@non_family_recipe.id)
        expect(actual_title).to eq(query_value)
        expect(json.count).to eq(1)
      end
    end
    context "PUT-PATCH /recipes Recipes#update" do
      before(:each) do
        @comparable = @family_recipe.first
        @recipe = FactoryBot.build(:recipe, member_id: @member.id)
        @update_params = {
          "attributes": {
            "title": @recipe.title,
            "description": @recipe.description,
            "ingredients_list": @recipe.ingredients_list
          }
        }
        @auth_headers = @member.create_new_auth_token
      end
      it "#put 403 on non-member" do
        put "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
      it "#patch 403 on non-member" do
        patch "/v1/recipes/#{@comparable.id}", :params => {:recipe => @update_params}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
    context "DELETE /recipes Recipes#destroy" do
      before(:each) do
        @comparable = @family_recipe.first
        @auth_headers = @member.create_new_auth_token
      end
      it "403 error" do
        delete "/v1/recipes/#{@comparable.id}", :params => {:id => @comparable.id}, :headers => @auth_headers
        expect(response).to have_http_status(403)
      end
    end
  end # Members / Unauthorized to Family Describe
  
  describe ':: Unknown User ::' do
    before do
      @member = nil
    end
    context "GET /recipes Recipes#index" do
      it "returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end
    context "GET /recipes Recipes#show" do
      it "returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end
    context "POST /recipes Recipes#create" do
      it "returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end
    context "PUT-PATCH /recipes Recipes#update" do
      it "#put returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
      it "#patch returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end
    context "DELETE /recipes Recipes#destroy" do
      it "returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end
    context "GET /recipes Recipes#search" do
      it "returns a 401 error saying they are not authenticated" do
        get '/v1/recipes'
        expect(response).to have_http_status(401)
      end
    end

  end # Unknown User Describe

end # Recipe RSpec
