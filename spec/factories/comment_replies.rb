FactoryBot.define do
  factory :comment_reply do
    body { Faker::Lorem.paragraph(2, false, 4) }
    created_at { created_at = Faker::Date.between(5.days.ago, 3.weeks.ago) }
    updated_at { created_at }
  end
end
