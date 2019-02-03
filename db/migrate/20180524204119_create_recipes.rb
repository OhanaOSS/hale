class CreateRecipes < ActiveRecord::Migration[5.2]
  def change
    create_table :recipes do |t|
      t.string :title, :null => false
      t.text :description
      t.json :steps
      t.text :ingredients_list, array: true
      t.text :tags_list, array: true
      t.references :member
      t.timestamps
    end
  end
end
