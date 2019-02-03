class CommentReply < ApplicationRecord
  include Interaction
  include Notifiable

  has_paper_trail
  belongs_to :member
  belongs_to :comment

    
  validates :body, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates_presence_of :body
  validates_presence_of :comment_id
  validates_presence_of :member_id

  def mentioned_members
    MentionParser.new(body).members
  end
end
