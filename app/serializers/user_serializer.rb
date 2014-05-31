class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :from_oauth, :image

  has_many :authentications
  embed :ids, include: true

  def image
    object.image_url
  end
end
