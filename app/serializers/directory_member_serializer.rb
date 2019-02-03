class DirectoryMemberSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type "member"

  attributes :id, :name, :surname, :nickname, :avatar

  def avatar # Required to avoid n+1 serialization failures.
    object.avatar.attached? ? rails_blob_path(object.avatar) : "assets/images/default_avatar.png"
  end

  link(:self) { api_v1_member_path(id: object.id) }

  has_many :families, through: :family_members, serializer: FamilySerializer do
    object.families.each do |family|
      link(:related) { api_v1_family_path(id: family.id) }
    end
  end
end