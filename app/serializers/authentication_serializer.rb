class AuthenticationSerializer < ActiveModel::Serializer
  attributes :id, :uid, :provider

  has_one :user
  embed :ids#, include: true
end
