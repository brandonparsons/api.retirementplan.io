require 'spec_helper'

describe Finance::PrattArrow do

  specify "::calculate_pratt_arrow_risk_aversion" do
    market_return     = 0.13
    market_std_dev    = 0.08
    risk_free_return  = 0.04
    stock_ratio       = 0.6

    pratt_arrow = Finance::PrattArrow.calculate_pratt_arrow_risk_aversion market_return, risk_free_return, stock_ratio, market_std_dev
    expect(pratt_arrow).to be_within(0.01).of(23.43749)
  end

  specify "::calculate_portfolio_utility" do
    pratt_arrow_risk_aversion = 1.3

    portfolio_return = 0.12
    portfolio_stddev = 0.05

    utility = Finance::PrattArrow.calculate_portfolio_utility pratt_arrow_risk_aversion, portfolio_return, portfolio_stddev

    expect(utility).to be_within(0.01).of(0.118375)
  end

end
