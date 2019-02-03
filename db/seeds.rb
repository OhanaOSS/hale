# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

  # Built a while loop like this to avoid
  # having too many records initally and so it's fast.
  # You can run db:seed many times as you want.
  def random_recipe_in_the_family(family_id)
    recipe = nil
    counter = 0
    while recipe == nil
      recipe = FamilyMember.where(family_id: family_id).order("RANDOM()").limit(1).first.member.recipes.first
      counter += 1
      break if counter >= 3
    end
    return recipe unless recipe.nil?
    new_family_member = FactoryBot.create(:family_member, family_id: family_id, member_id: Recipe.first.member_id)
    puts """
    Well, it looks like family_id: #{family_id} didn't have any recipes for their event_rsvp! \n
    That's ok! You just adopted #{new_family_member.member.name}(id:#{new_family_member.member.id}) into the #{new_family_member.family.family_name} family! Congrats!
    Now you can use her recipe!
    """
    return new_family_member.member.recipes.first
  end

  t = Time.now.to_i
  3.times do
    Family.create(
      family_name: Faker::Name.last_name
    )
  end
  t2 = Time.now.to_i
  puts "Finished families in #{t2-t} seconds."

  15.times do

    new_member = Member.create(
      name: Faker::Name.first_name,
      surname: Faker::Name.last_name,
      nickname: Faker::RickAndMorty.character,
      birthday: Faker::Date.birthday(13, 65),
      gender: rand(0..2),
      email: Faker::Internet.email,
      password: "password",
      contacts: {

      },
      addresses: {
        "home" => {
          "street_address" => Faker::Address.street_address,
          "secondary_address" => [nil, Faker::Address.secondary_address].sample,
          "city" => Faker::Address.city,
          "state" => Faker::Address.state_abbr,
          "zip" => Faker::Address.zip_code,
          "country" => "USA"
        }
      },
      instagram: Faker::Internet.domain_word
    )
    new_member.avatar.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
    FamilyMember.create(
      family_id: rand(1..Family.count),
      member_id: new_member.id
    )  
  end
  t3 = Time.now.to_i
  puts "Finished members in #{t3-t2} seconds and has been #{t3-t} seconds since start of seeds.rb."
  member_size = Member.count
  10.times do
    @member = FamilyMember.where(member_id: rand(1..member_size)).first
    @post = FactoryBot.create(:post,
      family_id: @member.family_id,
      member_id: @member.member_id
    )
    @post.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
        FactoryBot.create(:reaction,
          member_id: FamilyMember.where(family_id: @member.family_id).order("RANDOM()").limit(1).first.member_id,
          interaction_type: "Post",
          interaction_id: @post.id
        )
    rand(1..5).times do
      @comment = FactoryBot.create(:comment,
        member_id: FamilyMember.where(family_id: @member.family_id).order("RANDOM()").limit(1).first.member_id,
        commentable_type: "Post",
        commentable_id: @post.id
      )
      @comment.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
      rand(0..3).times do
        FactoryBot.create(:reaction,
          member_id: FamilyMember.where(family_id: @member.family_id).order("RANDOM()").limit(1).first.member_id,
          interaction_type: "Comment",
          interaction_id: @comment.id
        )
      end
      rand(0..3).times do
        comment = FactoryBot.create(:comment_reply,
          member_id: FamilyMember.where(family_id: @member.family_id).order("RANDOM()").limit(1).first.member_id,
          comment_id: @comment.id
        )
      end
    end
    puts "Created post #{@post.id} with #{@post.reactions.count} reactions and with #{@post.comments.count} comments with comment_replies/reactions."
  end
  t4 = Time.now.to_i
  puts "Finished posts with comments and comment_replies in #{t4-t3} seconds and has been #{t4-t} seconds since start of seeds.rb."
  5.times do
    recipe_hash = 
    {
      "ingredients_list": [],
      "tags_list": [],
      "steps": {
        "preparation": [],
        "cooking": [],
        "post_cooking": []
      }
    }
    recipe_hash[:steps].each_key do |key|
      rand(1..5).times do
        hash = {"instruction": "#{Faker::Lorem.sentence(5, true, 5)}", "ingredients": Array.new(rand(2..4)) { Faker::Food.ingredient }, "time_length": "#{rand(1..59)} minutes"}
        recipe_hash[:steps][key] << hash
        # Merge hash into generate ingredients_list.
        recipe_hash[:ingredients_list] = recipe_hash[:ingredients_list] | hash[:ingredients]
      end
    end
    # Generate tags_list.
    recipe_hash[:tags_list] = Array.new(rand(1..5)) { {title: Faker::Lorem.word, description: Faker::RickAndMorty.quote, mature: [true,false].sample} }
    # Format to match RecipeFactory inputs.
    recipe_params_hash = {
      attributes: {
        title: Faker::Food.dish,
        description: Faker::Lorem.sentence(5, true, 5),
        member_id: rand(1..member_size),
        steps: recipe_hash[:steps].to_h,
        ingredients_list: recipe_hash[:ingredients_list],
        tags_list: recipe_hash[:tags_list]
      }
    }
    # Convert from sym hash to string hash via params to match RecipeFactory inputs.
    recipe_params = ActionController::Parameters.new(recipe_params_hash).permit!
    # Create Recipe.new && generate Tag records and Ingredients records contained in their lists.
    recipe = RecipeFactory.new(recipe_params).result
    # Save the Recipe record.
    recipe.save!
    # Callback to RecipeFactory with Recipe ID to generate RecipeTag records and RecipeIngredients records
    # via find_or_create_by with ingredients_list and tags_list.
    RecipeFactory.new(recipe_params).factory_callback(recipe.id)
    # Attach media to record.
    recipe.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
    puts "Created recipe_id #{recipe.id} with #{recipe.tags.count} tags and #{recipe.ingredients.count} ingredients."
  end
  t5 = Time.now.to_i
  puts "Finished recipes in #{t5-t4} seconds and has been #{t5-t} seconds since start of seeds.rb."
  5.times do
    family_member = FamilyMember.where( member_id: rand(1..member_size) ).first
    event = FactoryBot.create(:event, family_id: family_member.family_id, member_id: family_member.member_id)
    event.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
    rand(1..5).times do
      rand_num = rand(2..6)
      party_companions = FamilyMember.where(family_id: event.family_id).order("RANDOM()").limit(rand_num).pluck(:member_id)
      if rand_num < 4
        event_rsvp = FactoryBot.create(:event_rsvp, party_size: party_companions.size, rsvp: "yes", bringing_food: false, recipe_id: nil, non_recipe_description: nil, serving: 0, member_id: party_companions.first, party_companions: party_companions, event_id: event.id)
        puts "Aww, member_id: #{event_rsvp.member_id} isn't bringing any food to event_id: #{event.id} with their group of #{party_companions.size} according to event_rsvp: #{event_rsvp.id}."
      elsif rand_num >= 5
        event_rsvp = FactoryBot.create(:event_rsvp, party_size: party_companions.size, rsvp: "yes", bringing_food: true, recipe_id: random_recipe_in_the_family(event.family_id), non_recipe_description: nil, serving: (party_companions.size + 5 ), member_id: party_companions.first, party_companions: party_companions, event_id: event.id)
        puts "Ohh, member_id: #{event_rsvp.member_id} is bringing a family recipe to event_id: #{event.id} with their group of #{party_companions.size} according to event_rsvp: #{event_rsvp.id}."
      else
        event_rsvp = FactoryBot.create(:event_rsvp, party_size: party_companions.size, rsvp: "yes", bringing_food: true, recipe_id: nil, non_recipe_description: Faker::RickAndMorty.quote, serving: (party_companions.size + 3 ), member_id: party_companions.first, party_companions: party_companions, event_id: event.id)
        puts "Ohh, member_id: #{event_rsvp.member_id} is bringing some new food to event_id: #{event.id} with their group of #{party_companions.size} according to event_rsvp: #{event_rsvp.id}."
      end
    end
    puts "Created event_id #{event.id} with #{event.event_rsvps.count} rsvps."
  end
  t6 = Time.now.to_i
  puts "Finished events with event_rsvps in #{t6-t5} seconds. It took #{t6-t} seconds since start of seeds.rb."