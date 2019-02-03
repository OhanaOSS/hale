FactoryBot.define do
  factory :family_member do
    family_id { FactoryBot.create(:family).id }
    member_id { FactoryBot.create(:member).id }
  end
end
