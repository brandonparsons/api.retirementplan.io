class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :has_password, :image

  has_many :authentications
  embed :ids, include: true

  def image
    object.image_url
  end

  def has_password
    object.password_digest.present?
  end

end
