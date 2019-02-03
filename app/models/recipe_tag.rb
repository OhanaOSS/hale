class RecipeTag < ApplicationRecord
  belongs_to :recipe, optional: true
  belongs_to :tag, optional: true

  validates_presence_of :recipe_id
  validates_presence_of :tag_id
end
