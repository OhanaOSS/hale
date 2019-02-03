FactoryBot.define do
  factory :invite do
    email { Faker::Internet.email }
  end
end
