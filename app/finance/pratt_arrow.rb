module Finance
  module PrattArrow

    extend self

    def calculate_pratt_arrow_risk_aversion(market_return, risk_free_return, stock_ratio, market_std_dev)
      pratt_arrow_risk_aversion = ( market_return - risk_free_return ) / stock_ratio  / ( market_std_dev ** 2 )
      return pratt_arrow_risk_aversion
    end

  end
end
