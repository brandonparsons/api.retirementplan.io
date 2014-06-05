class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :image, :has_password, :confirmed

  has_many :authentications
  embed :ids, include: true

  def image
    object.image_url
  end

  def has_password
    object.has_password?
  end

  def confirmed
    object.confirmed?
  end

end
