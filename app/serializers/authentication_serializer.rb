class AuthenticationSerializer < ActiveModel::Serializer
  attributes :id, :uid, :provider, :username

  has_one :user
  embed :ids#, include: true
end
