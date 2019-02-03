FactoryBot.define do
  factory :event_rsvp do
    # before(:create) do
    #   recipe = FactoryBot.create(:recipe, evaluator.comment_count, member_id: Member.last.id)
    #   party = []
    #   rand(1..5).times { party << FactoryBot.create(:family_member).member_id }
    # end
    # party_size { party.size }
    # rsvp { 0 }
    # bringing_food { true }
    # # recipe_id { recipe.id }
    # serving { rand(3..15) }
    # member_id { party.slice!(0) }
    # party_companions { party }
    # event_id {  } gets passed
    rsvp_note { Faker::Lorem.paragraph(2, false, 1) }
    created_at { created_at = Faker::Date.between(5.days.ago, 3.weeks.ago) }
    updated_at { created_at }
  end
end
