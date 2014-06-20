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

end
