class PortfolioSerializer < ActiveModel::Serializer
  attributes :id, :weights, :current_shares, :selected_etfs, :tracking

  def weights
    object.weights.reduce({}) do |memo, (assetId, weight)|
      memo[assetId] = weight.to_f
      memo
    end
  end

  def current_shares
    object.current_shares.reduce({}) do |memo, (ticker, number_of_shares)|
      memo[ticker] = number_of_shares.to_i
      memo
    end
  end

end
