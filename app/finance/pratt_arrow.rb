module Finance
  module PrattArrow

    extend self

    def calculate_pratt_arrow_risk_aversion(market_return, risk_free_return, stock_ratio, market_std_dev)
      pratt_arrow_risk_aversion = ( market_return - risk_free_return ) / stock_ratio  / ( market_std_dev ** 2 )
      return pratt_arrow_risk_aversion
    end

    def calculate_portfolio_utility(pratt_arrow_risk_aversion, portfolio_return, portfolio_std_deviation)
      # See dissertation equation 3.1 pg. 90
      utility = portfolio_return - ( pratt_arrow_risk_aversion / 2  ) * ( portfolio_std_deviation ** 2 )
      return utility
    end

  end
end
