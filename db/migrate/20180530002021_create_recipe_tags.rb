class CreateRecipeTags < ActiveRecord::Migration[5.2]
  def change
    create_table :recipe_tags do |t|
      t.references :recipe, null: false
      t.references :tag, null: false
      t.timestamps
    end
  end
end
