class Comment < ApplicationRecord
  include Interaction
  include Notifiable
  
  has_paper_trail

  belongs_to :commentable, polymorphic: true
  belongs_to :member
  has_one_attached :media

  has_many :comment_replies
  
  validates :body, presence: true, length: { minimum: 1 }, 
    format: { 
      with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, 
      message: "only allows letters and \"'-.!?;" 
    }, unless: Proc.new { (self.body.present? == true && self.media.attached? == true) || self.media.attached? }, on: :create

  validates_presence_of :commentable_id
  validates_presence_of :commentable_type
  validates_presence_of :member_id

  def self.comment_replies
    CommentReply.where(comment_id: ids)
  end

  def mentioned_members
    MentionParser.new(body).members
  end
end
