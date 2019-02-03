FactoryBot.define do
  factory :recipe do
    title { Faker::Food.dish }
    description { Faker::Lorem.sentence }
    steps { "Use #{Faker::Food.measurement} of #{Faker::Food.ingredient}" }
    ingredients_list { [["Asafoetida", "Dandelion", "Tea", "Vinegar", "Lettuce", "Tea", "Fennel Seeds"], ["Achacha", "Omega Spread", "Enoki Mushrooms", "Cheddar", "Cinnamon", "Tahini", "Mandarins"], ["Nutritional Yeast", "SwedeSweet Chilli Sauce", "Sprouts", "Cumquat", "Duck", "Chives", "Wakame"]].sample }
    tags_list { ["tasty", "vegan", "easy to make"] }
    member_id { FactoryBot.create(:family_member).member.id }
  end
end
