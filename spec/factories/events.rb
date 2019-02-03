FactoryBot.define do
  factory :event do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph(2, false, 4) }
    event_start { Faker::Date.forward(5.days) }
    event_end { Faker::Date.forward(5.days) }
    event_allday { [true, false].sample }
    location { [Faker::Address.latitude.to_f.truncate(15), Faker::Address.longitude.to_f.truncate(15)] }
    potluck { [true, false].sample }
    locked { [true, false].sample }
    # family_id {  } gets passed
    # member_id {  } gets passed
    # event_rsvp_id {  }
    created_at { Faker::Date.between(5.months.ago, 3.weeks.ago) }
    updated_at { Faker::Date.between(5.months.ago, 3.weeks.ago) }
  end
end
