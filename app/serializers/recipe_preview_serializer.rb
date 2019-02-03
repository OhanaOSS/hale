class RecipePreviewSerializer < ActiveModel::Serializer
  attributes :id, :title, :description

  link(:self) { api_v1_recipes_path(id: object.id) }
end
