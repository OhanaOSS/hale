class FamilyConfigSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type "family-config"

  attributes :id, :family_id, :authorization_enabled, :created_at, :updated_at

end
