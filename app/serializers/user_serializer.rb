class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :from_oauth

  has_many :authentications
  embed :ids, include: true
end
