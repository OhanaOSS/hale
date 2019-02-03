class CreateRecipeIngredients < ActiveRecord::Migration[5.2]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false
      t.references :ingredient, null: false
      t.timestamps
    end
  end
end
