FactoryBot.define do
  factory :ingredient do
    title { Faker::Food.ingredient }
  end
end
