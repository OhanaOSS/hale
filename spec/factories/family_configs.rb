FactoryBot.define do
  factory :family_config do
    family_id { FactoryBot.create(:family) }
    authorization_enabled { "true" }
    created_at { DateTime.now }
    updated_at { DateTime.now }
  end
end
