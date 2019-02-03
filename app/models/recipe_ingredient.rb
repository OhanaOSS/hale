class RecipeIngredient < ApplicationRecord
  belongs_to :recipe, optional: true
  belongs_to :ingredient, optional: true

  validates_presence_of :recipe_id
  validates_presence_of :ingredient_id
end
