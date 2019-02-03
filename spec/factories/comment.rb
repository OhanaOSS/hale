# 
FactoryBot.define do
  factory :comment do
    body Faker::Lorem.paragraph(1, false, 2)
    created_at Faker::Date.between(2.weeks.ago, Date.today)
    updated_at Faker::Date.between(2.weeks.ago, Date.today)
  end
end