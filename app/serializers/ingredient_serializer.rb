class IngredientSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  type "ingredient"
  attributes :id, :title

  link(:self) { api_v1_ingredient_path(object.id) }

end
