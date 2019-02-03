class FamilySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type "family"

  attributes :id, :family_name

  link(:self) { api_v1_family_path(id: object.id) }
end
