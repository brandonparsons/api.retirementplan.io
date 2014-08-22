class AdminPortfolioSerializer < PortfolioSerializer
  attributes :market_value, :in_balance

  def market_value
    # Report no value if they haven't set up yet.....
    object.current_shares.present? ? object.send(:current_market_value) : 0.0
  end

  def in_balance
    # Report in balance if they haven't set up yet....
    object.current_shares.present? ? object.out_of_balance?(0.05) : true
  end

end
