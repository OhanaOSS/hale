class Recipe < ApplicationRecord
  include Interaction
  include Commentable
  
  belongs_to :member

  has_many :recipe_ingredients, :class_name => 'RecipeIngredient'
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_tags, :class_name => 'RecipeTag'
  has_many :tags, through: :recipe_tags
  has_one_attached :media

  validates :title, presence: true, length: { maximum: 120 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates :description, presence: true, length: { maximum: 300 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates :steps, presence: true
  validates :ingredients_list, presence: true
  validates :tags_list, presence: true
  validates :member_id, presence: true
end
