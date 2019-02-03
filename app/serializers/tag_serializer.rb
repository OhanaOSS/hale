class TagSerializer < ActiveModel::Serializer
  type "tag"
  attributes :id, :title, :description, :mature
end
