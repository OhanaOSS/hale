class CreateCommentReplies < ActiveRecord::Migration[5.2]
  def change
    create_table :comment_replies do |t|
      t.text :body, :null => false
      t.text :edit
      t.references :comment
      # t.references :commentable, null: false, polymorphic: true, index: true
      t.references :member
      t.timestamps
    end
  end
end
