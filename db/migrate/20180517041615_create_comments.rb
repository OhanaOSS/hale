class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.text :body, :null => false
      t.text :edit
      t.references :commentable, null: false, polymorphic: true, index: true
      t.integer :member_id
      t.timestamps
    end
  end
end
