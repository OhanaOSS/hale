class RecipeSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  type "recipe"
  attributes :id, :title, :description, :steps, :media, :ingredients_list, :tags_list, :member_id, :created_at, :updated_at

  def media # Required to avoid n+1 serialization failures.
    object.media.attached? ? rails_blob_path(object.media) : nil
  end

  link(:self) { api_v1_recipes_path(id: object.id) }

  has_one :member, serializer: MemberPreviewSerializer do
    link(:related) { api_v1_member_path(object.member_id) }
  end

  has_many :tags, serializer: TagSerializer
  has_many :ingredients, serializer: IngredientSerializer
  has_many :reactions, serializer: ReactionPreviewSerializer do
    link(:related) { api_v1_recipe_reactions_path(object.id) }
  end

end
