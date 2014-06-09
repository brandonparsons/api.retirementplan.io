class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :image, :has_password, :confirmed,
    :completed_questionnaire

  has_many  :authentications
  has_one   :questionnaire

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

  def completed_questionnaire
    object.has_completed_questionnaire?
  end

end
