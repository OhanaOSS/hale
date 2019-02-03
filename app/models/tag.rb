class Tag < ApplicationRecord
  has_many :recipe_tags, :class_name => 'RecipeTag', inverse_of: :tag
  has_many :recipes, through: :recipe_tags

  validates :title, presence: true, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates :description, allow_blank: true, length: { minimum: 1 }, format: { with: /[A-Za-z\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s"'-.!?;]+/, message: "only allows letters and \"'-.!?;" }
  validates :mature, inclusion: { in: [ true , false ] }, exclusion: { in: [nil] }

end
