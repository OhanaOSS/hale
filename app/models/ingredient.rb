class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, :class_name => 'RecipeIngredient', inverse_of: :ingredient
  has_many :recipes, through: :recipe_ingredients

  validates :title, presence: true, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }

end
