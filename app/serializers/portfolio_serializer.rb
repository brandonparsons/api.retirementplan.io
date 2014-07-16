class PortfolioSerializer < ActiveModel::Serializer
  attributes :id, :weights, :current_shares, :selected_etfs, :tracking

  def weights
    FloatMapper.call(object.weights) if object.weights.present?
  end

  def current_shares
    FloatMapper.call(object.current_shares) if object.current_shares.present?
  end

end
