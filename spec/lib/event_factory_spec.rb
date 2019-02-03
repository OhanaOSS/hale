
require "rails_helper"
require "recipe_factory"

# This is a two-step factory that loops using find_or_create_by to create/locate
# Ingredients and Tags initally returning a valid Recipe.new record to 
# the Recipe Controller. The callback takes the newly saved recipe_id to create
# join tables to the save recipe. @new_recipe_params is the format the factory 
# takes after converting the params to a hash. The formatting for the steps
# takes place on the front end.

RSpec.describe EventFactory do
  before do
    @family = FactoryBot.create(:family)
    @member = FactoryBot.create(:family_member, family_id: @family.id ,authorized_at: DateTime.now).member
    @new_event_params = ActionController::Parameters.new({
      "attributes"=> {
        "title"=>"Facilis dolores recusandae aperiam ut qui.",
        "description"=>"Ipsam tenetur doloremque qui quae reiciendis autem. Ea qui omnis voluptas.",
        "event_start"=>"2018-08-15 00:00:00 UTC",
        "event_end"=>"2018-08-17 00:00:00 UTC",
        "family_id"=>@family.id,
        "member_id"=>@member.id,
        "location"=>["-22.04064343248484", "153.80209449075636"]
      }
    }).permit!
    @new_event_params_without_start_time = ActionController::Parameters.new({
      "attributes"=> {
        "title"=>"Facilis dolores recusandae aperiam ut qui.",
        "description"=>"Ipsam tenetur doloremque qui quae reiciendis autem. Ea qui omnis voluptas.",
        "family_id"=>@family.id.to_s,
        "member_id"=>@member.id.to_s,
        "location"=>["-22.04064343248484", "153.80209449075636"]
      }
    }).permit!
  end
  describe "Inital formatting of event based on inputs" do
    before do
    end
    it 'creates a valid Event.new record served to the Events Controller' do
      event = EventFactory.new(@new_event_params).result
      expect(event.instance_of?(Event)).to be true
      expect(event.valid?).to be true
      expect(event.save).to be true
    end
    it 'matches the input of @new_event_params' do
      expected = @new_event_params["attributes"].to_h
      event = EventFactory.new(@new_event_params).result
      expect(event.title).to eq(expected["title"])
      expect(event.description).to eq(expected["description"])
      expect(event.event_start).to eq(expected["event_start"])
      expect(event.event_end).to eq(expected["event_end"])
      expect(event.family_id).to eq(expected["family_id"])
      expect(event.member_id).to eq(expected["member_id"])
      expect(event.location[0]).to eq(expected["location"][0].to_f)
      expect(event.location[1]).to eq(expected["location"][1].to_f)
    end
    it 'takes new params without start time and creates event today' do
      expected = @new_event_params_without_start_time["attributes"].to_h
      event = EventFactory.new(@new_event_params_without_start_time).result
      expect(event.event_start).to eq(DateTime.parse("#{Date.today} 00:00:00"))
      expect(event.event_end).to eq(DateTime.parse("#{Date.today} 23:59:59"))
    end
  end
  describe 'factory callback' do
    before do
      @event_to_callback = EventFactory.new(@new_event_params).result
      @event_to_callback.save
    end
    it 'creates the inital event_rsvp of the parent event from the callback' do
      event_rsvp = EventFactory.new(@event_to_callback).event_creator_rsvp
      expect(event_rsvp.instance_of?(EventRsvp)).to be true
      expect(event_rsvp.valid?).to be true
      expect(event_rsvp.member_id).to eq(@event_to_callback.member_id)
      expect(event_rsvp.event_id).to eq(@event_to_callback.id)
      expect(event_rsvp.party_size).to eq(1)
      expect(event_rsvp.rsvp).to eq("yes")
      expect(event_rsvp.bringing_food).to eq(false)
      expect(event_rsvp.recipe_id).to eq(nil)
      expect(event_rsvp.serving).to eq(0)
      expect(event_rsvp.non_recipe_description).to eq(nil)
      expect(event_rsvp.party_companions).to eq([])
      expect(event_rsvp.rsvp_note).to eq(nil)
      expect(event_rsvp.save).to be true
      expect(event_rsvp.id).to_not be_nil
    end
  end
end