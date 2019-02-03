FactoryBot.define do
  factory :tag do
    title { ["tasty", "vegan", "easy to make"].sample }
    description { Faker::Lorem.paragraph }
    mature { [true, false].sample }
  end
end
