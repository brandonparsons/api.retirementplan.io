# require 'matrix'

module Finance
  module ReversePortfolioOptimization
    ####
    # This class is a Ruby implementation of your original data crunching in a
    # Google Doc. See first pass here:
    # https://docs.google.com/a/easyretirementplanning.ca/spreadsheet/ccc?key=0Ap94IzrZKBS7dHBDZ0M3cVRoQnVXQjU2QzRKVzF3cHc&usp=drive_web#gid=3
    # Is pulls data from flat YAML files - not the database.
    ####


    extend self


    # FIXME: Some way to remember these need updating periodically?
    # FIXME: Updated Dec 17th - 2013. Need to update occasionally (along with returns).
    LONG_TERM_INFLATION         = 0.0175 # Cleveland Federal Reserve - http://www.clevelandfed.org/research/data/inflation_expectations/
    ANNUAL_RISKLESS_RATE        = 0.0013 # 12-month U.S. T-Bill - http://www.bloomberg.com/markets/rates-bonds/government-bonds/us/
    ANNUAL_MARKET_RISK_PREMIUM  = 0.0532 # http://pages.stern.nyu.edu/~%20adamodar/
    REAL_ANNUAL_RISKLESS_RATE   = (1 + ANNUAL_RISKLESS_RATE) / (1 + LONG_TERM_INFLATION) - 1
    REAL_WEEKLY_RISKLESS_RATE   = (1 + REAL_ANNUAL_RISKLESS_RATE) ** (1.0/52.0) - 1
    WEEKLY_MARKET_RISK_PREMIUM  = (1 + ANNUAL_MARKET_RISK_PREMIUM) ** (1.0/52.0) - 1


    def perform
      determine_implied_asset_returns
    end


    private

    def determine_implied_asset_returns
      implied_weekly_returns = {}

      determine_asset_betas.each_pair do |ticker, beta|
        implied_weekly = REAL_WEEKLY_RISKLESS_RATE + ( WEEKLY_MARKET_RISK_PREMIUM * beta )
        implied_weekly_returns[ticker] = implied_weekly
        # implied_annual_returns[ticker] = ( (1 + implied_weekly)**52.0 -1 ).to_f
      end

      implied_weekly_returns
    end

    def determine_asset_betas
      # -- Beta asset = covar(assets, mkt port) / var(mkt port)
      #   -> covar(assets, mkt port) = weighted average of covar(assets) using
      #      mkt port proporations as weights
      #   -> var(mkt port) = weighted average of covar(assets) with market using
      #      market proportions as weights

      # A) Determine covariance of each asset with the market portfolio
      covars_with_mkt_port           = []
      market_portfolio_percentages  = market_portfolio_composition.map { |k,v| v }

      (0...covariances.row_size).each do |row_index|
        covariance_row = covariances.row(row_index)
        sumproduct = covariance_row.zip(market_portfolio_percentages).inject(0) {|r, (a, b)| r + (a * b)}
        covars_with_mkt_port << sumproduct
      end

      # B) Variance of market portfolio
      mkt_port_variance = covars_with_mkt_port.zip(market_portfolio_percentages).inject(0) {|r, (a, b)| r + (a * b)} # another sumproduct

      # C) Calculate betas
      betas = {}
      tickers = market_portfolio_composition.keys
      tickers.each_with_index do |ticker, index|
        betas[ticker] = covars_with_mkt_port[index] / mkt_port_variance
      end

      betas
    end

    def market_portfolio_composition
      Finance::MarketPortfolioComposition.values
    end

    def covariances
      # Memoize - right now this is only called once, but just in case. Don't
      # want to be recalculating covariance matrices multiple times.

      # Using Rails.cache alone here doesn't appear to work (at least in test --
      # super slow. Probably because of :null_store)
      @covariances ||= begin

        # Can get away with a longer expire time here as you are checking the return
        # value of `excess_returns` as part of the hash key (which itself is cached,
        # but on 10.minute expiry).
        hash    = Digest::MD5.hexdigest(excess_returns.to_json)
        covars  = Rails.cache.fetch("reverseportopt/covariances/#{hash}", expires_in: 12.hours) do
          Finance::MatrixMethods.covariance(excess_returns)
        end

        covars
      end
    end

    def excess_returns
      # Memoize - this gets called hundreds of times.
      Rails.cache.fetch("reverseportopt/excess_returns", expires_in: 10.minutes) do
        time_period_riskless_returns = TBill.returns
        excess_returns = {}

        returns.each_pair do |ticker, return_array|
          excess_vals = []

          return_array.each_with_index do |val, index|
            excess_vals << val - time_period_riskless_returns[index] + REAL_WEEKLY_RISKLESS_RATE
          end

          excess_returns[ticker] = excess_vals
        end

        excess_returns
      end
    end

    def returns
      Finance::ReturnData.values
    end

  end
end
