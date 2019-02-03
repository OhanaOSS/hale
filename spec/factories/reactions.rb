FactoryBot.define do
  factory :reaction do
    member_id { nil }
    emotive { Reaction.emotives.keys.sample }
    interaction_type { nil }
    interaction_id { nil }
    created_at { DateTime.new }
    updated_at { DateTime.new }
  end
end
# FactoryBot.create(:reaction, member_id: nil, interaction_type: String, interaction_id: Int)