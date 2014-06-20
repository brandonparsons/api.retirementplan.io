class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :image, :pratt_arrow_low, :pratt_arrow_high,
    :has_password, :confirmed, :accepted_terms, :has_completed_questionnaire,
    :has_selected_portfolio, :has_completed_simulation, :has_tracked_portfolio

  has_many  :authentications
  has_one   :questionnaire

  embed :ids, include: true

  def image
    object.image_url
  end

  def pratt_arrow_low
    object.questionnaire.present? ? object.questionnaire.pratt_arrow_low : nil
  end

  def pratt_arrow_high
    object.questionnaire.present? ? object.questionnaire.pratt_arrow_high : nil
  end

  def has_password
    object.has_password?
  end

  def confirmed
    object.confirmed?
  end

  def accepted_terms
    object.has_accepted_terms?
  end

  def has_completed_questionnaire
    object.has_completed_questionnaire?
  end

  def has_selected_portfolio
    object.has_selected_portfolio?
  end

  def has_completed_simulation
    object.has_completed_simulation?
  end

  def has_tracked_portfolio
    object.has_setup_tracked_portfolio?
  end

end
