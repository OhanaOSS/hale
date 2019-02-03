# 
FactoryBot.define do
require 'pry'
  factory :post do

    body { Faker::Lorem.paragraph(2, false, 4) }
    location { [Faker::Address.latitude.to_f.truncate(15), Faker::Address.longitude.to_f.truncate(15)] }
    created_at { Faker::Date.between(5.months.ago, 3.weeks.ago) }
    updated_at { Faker::Date.between(5.months.ago, 3.weeks.ago) }
    family_id { @family = FactoryBot.create(:family).id }
    member_id { FactoryBot.create(:family_member, family_id: @family).member_id }

    factory :post_with_children do      
      after :create do |post|
        @family_id = post.family_id
        rand(1..9).times do 
          member_id = FactoryBot.create(:family_member, family_id: @family_id).member.id
          FactoryBot.create(:reaction, member_id: member_id, interaction_type: "Post", interaction_id: post.id)
        end

        member_id = FactoryBot.create(:family_member, family_id: @family_id).member.id
        FactoryBot.create_list(:comment, 3, commentable_id: post.id, commentable_type: "Post", member_id: member_id )
       
        post.comments.each do |comment|
          rand(1..3).times do 
            member_id = FactoryBot.create(:family_member, family_id: @family_id).member.id
            FactoryBot.create(:reaction, member_id: member_id, interaction_type: "Comment", interaction_id: comment.id)
          end
          FactoryBot.create_list(:comment_reply, 3, comment_id: comment.id, member_id: FactoryBot.create(:family_member, family_id: comment.member.family_ids.first).member )
          comment.comment_replies.each do |comment_reply|
            rand(1..2).times do 
              member_id = FactoryBot.create(:family_member, family_id: @family_id).member.id
              FactoryBot.create(:reaction, member_id: member_id, interaction_type: "CommentReply", interaction_id: comment_reply.id)
            end
          end
        end
      end
    end
  end
end
