FactoryBot.define do
  factory :family do
    family_name { Faker::Name.last_name }
  end
end
