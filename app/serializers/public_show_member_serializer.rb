class PublicShowMemberSerializer < ActiveModel::Serializer
  attributes :id, :user_role, :image, :image_store, :name, :surname, :nickname, :gender, :bio, :birthday, :instagram, :email, :addresses, :contacts

end
