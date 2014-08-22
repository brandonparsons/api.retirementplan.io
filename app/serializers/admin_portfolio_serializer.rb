class PortfolioSerializer < ActiveModel::Serializer
  attributes :market_value, :in_balance

  def market_value
    object.send(:current_market_value)
  end

  def in_balance
    object.out_of_balance?(0.05)
  end

end
