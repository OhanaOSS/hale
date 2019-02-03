class EventFactory
  
  def initialize(event)

    if event.instance_of?(ActionController::Parameters)
      @event = event["attributes"]
      @title = @event["title"]
      @description = @event["description"]
      @member = Member.find(@event["member_id"])
      @family = Family.find(@event["family_id"])
      !@event["location"].present? ? @location = nil : @location = @event["location"]
      !@event["potluck"].present? ? @potluck = false : @potluck = @event["potluck"]
      !@event["locked"].present? ? @locked = false : @locked = @event["locked"]
      !@event["party_companions"].present? ? @party_companions = [] : @party_companions = @event["party_companions"]

      unless @event["event_start"].present? && @event["event_end"].present?
        @event_start = DateTime.parse("#{Date.today} 00:00:00")
        @event_end = DateTime.parse("#{Date.today} 23:59:59")
        @event_allday = true
      else
        @event_start = @event["event_start"].to_datetime
        @event_end = @event["event_end"].to_datetime
        @event["event_allday"].present? ? @event_allday = @event["event_allday"] : @event_allday = false
      end
    elsif event.instance_of?(Event)
      @event = event
      @member = Member.find(@event.member_id)
      @family = Family.find(@event.family_id)
    end
  end
  
  def event_creator_rsvp
    EventRsvp.new({
      party_size: 1,
      rsvp: "yes",
      bringing_food: false,
      recipe_id: nil,
      non_recipe_description: nil,
      serving: 0,
      member_id: @member.id,
      party_companions: [],
      event_id: @event.id,
      rsvp_note: nil
    })
  end

  def result
    Event.new({
      title: @title, # string
      description: @description, # text
      member_id: @member.id,
      family_id: @family.id,
      event_start: @event_start, 
      event_end: @event_end, 
      event_allday: @event_allday, 
      location: @location, 
      potluck: @potluck, 
      locked: @locked
    })
  end
end
