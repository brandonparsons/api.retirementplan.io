# require 'base64'
# require 'json'

module Finance
  module PortfolioBuilder

    extend self

    def async_portfolio_data_for_tickers(tickers, pratt_arrow_low, pratt_arrow_high)
      # If synchronous, running through entire method even if haven't generated
      # the frontier before.  If !syncronous, return nil if pushing to the
      # background (which caches the result).  The browser will try again in a
      # few seconds.

      raise "Tickers must be an array" unless tickers.is_a?(Array)
      tickers.sort!

      if have_frontier_in_cache?(tickers)
        return portfolio_data_for_tickers(tickers, pratt_arrow_low, pratt_arrow_high)
      else
        # Could just do `delay.portfolio_data_for_tickers....` but want to use
        # sidekiq unique jobs otherwise you are potentially queuing the same
        # tickers over and over.
        ::EfficientFrontierBuilder.perform_async(tickers)
        return nil
      end
    end

    def portfolio_data_for_tickers(tickers, pratt_arrow_low, pratt_arrow_high)
      # Portfolio generation was pulled into a private method so you can cache
      # for every efficient frontier. However, the utility is person dependent
      # (depends on risk tolerance), so have to add in after the fact.

      raise "Tickers must be an array" unless tickers.is_a?(Array)
      tickers.sort!

      portfolios = build_portfolios_for(tickers)
      portfolios.map do |portfolio|
        portfolio_return  = portfolio['weekly_expected_return']
        portfolio_risk    = portfolio['weekly_std_dev']

        portfolio['utility_high'] = Finance::PrattArrow.calculate_portfolio_utility(pratt_arrow_low,  portfolio_return, portfolio_risk).to_f
        portfolio['utility_low']  = Finance::PrattArrow.calculate_portfolio_utility(pratt_arrow_high, portfolio_return, portfolio_risk).to_f
      end

      return portfolios
    end

    def build_portfolios_for(tickers)
      ::RedisCache.fetch(results_cache_key_for(tickers), 2.weeks) do
        portfolios = allocations_for(tickers).map do |allocation|
          normalized_allocation = normalize_allocation(allocation)

          portfolio_statistics      = statistics_for_allocation(normalized_allocation)
          port_return               = portfolio_statistics[:expected_return]
          port_std_dev              = portfolio_statistics[:expected_std_dev]
          annual_nominal_return_pct = portfolio_statistics[:annual_nominal_return_pct].to_f
          annual_std_dev_pct        = portfolio_statistics[:annual_std_dev_pct].to_f

          {
            # These keys are depended on by javascript
            'id'                                => encode_allocation(normalized_allocation),
            'weights'                           => prettify_weights(normalized_allocation),
            'weekly_expected_return'            => port_return,  # Picked up in utility calc
            'weekly_std_dev'                    => port_std_dev, # Picked up in utility calc
            'risk'                              => annual_std_dev_pct,
            'return'                            => annual_nominal_return_pct,
            'monthly_expected_return_on_ten_k'  => Finance::Statistics.portfolio_monthly_return_for(10000, annual_nominal_return_pct/100.0).round(2),
            'daily_VAR_on_ten_k'                => Finance::Statistics.portfolio_daily_var_for(10000, annual_nominal_return_pct/100.0, annual_std_dev_pct/100.0).round(2),
            'warning_messages'                  => Portfolio.warnings_for(allocation)
          }
        end # allocations_for

        cull_portfolios(portfolios)
      end
    end

    def statistics_for_allocation(allocation, return_source=:implied_return)
      securities_hash   = summarize_security_data_for(allocation, return_source)
      expected_return   = calculate_expected_return_for(securities_hash)
      expected_std_dev  = calculate_expected_std_dev_for(securities_hash)

      {
        expected_return:            expected_return,
        expected_std_dev:           expected_std_dev,
        annual_nominal_return_pct:  ( (1 + expected_return) ** 52 - 1 ) * 100 + 2.0,
        annual_std_dev_pct:         expected_std_dev * Math.sqrt(52) * 100
      }
    end

    def prettify_weights(weights)
      weights.inject({}) do |h, (ticker, weight)|
        rounded_weight  = '%.1f' % (weight * 100)
        as_text         = "#{rounded_weight}%"
        h[Security.asset_class_for_ticker ticker] = as_text
        h
      end
    end

    def normalize_allocation(allocation)
      Hash[allocation.sort].inject({}) {|h, (k,v)| h[k.upcase] = v.to_f; h  }
    end

    def encode_allocation(allocation)
      Base64.urlsafe_encode64(allocation.to_json)
    end

    def decode_to_allocation(str)
      JSON.parse(Base64.urlsafe_decode64 str)
    end

    def warm_cache
      # Build all 1,2 and 3 asset efficient frontiers in cache.
      tickers = Security.all_tickers
      tickers.each { |ticker| build_portfolios_for [ticker] } # Singles
      tickers.combination(2).to_a.each { |combo| build_portfolios_for combo } # Doubles
      tickers.combination(3).to_a.each { |combo| build_portfolios_for combo } # Triples
    end


    private

    def have_frontier_in_cache?(tickers)
      RedisCache.has_key?(results_cache_key_for tickers)
    end

    def results_cache_key_for(tickers)
      ["portfolios_for", tickers.join('-'), Security.last_updated_time].join("/")
    end

    def summarize_security_data_for(allocation, return_source)
      tickers         = allocation.keys.sort
      securities_hash = Security.statistics_for(tickers, return_source).inject({}) do |h, security|
        h[security[:ticker]] = {
          weight:       allocation[security[:ticker]],
          mean_return:  security[:mean_return],
          std_dev:      security[:std_dev],
          returns:      security[:returns]
        }
        h
      end
    end

    def calculate_expected_return_for(securities_hash)
      securities_hash.reduce(0.0) do |sum, (ticker, data)|
        sum += data[:weight].to_f * data[:mean_return].to_f
      end
    end

    def calculate_expected_std_dev_for(securities_hash)
      # Don't need the weights / implied returns etc. for the correlation method.
      # Pluck out the returns:
      returns_hash        = securities_hash.inject({}) { |h, (k,v)| h[k] = v[:returns]; h}
      correlation_matrix  = Finance::MatrixMethods.correlation(returns_hash)
      variance = 0.0
      securities_hash.each_with_index do |(ticker1, data1), i|
        securities_hash.each_with_index do |(ticker2, data2), j|
          variance += data1[:weight].to_f * data2[:weight].to_f * data1[:std_dev].to_f * data2[:std_dev].to_f * correlation_matrix[i,j]
        end
      end
      Math.sqrt(variance)
    end

    def cull_portfolios(portfolios)
      # Only include the top-half of the frontier - i.e. portfolios with the
      # highest return for a given level of risk.
      portfolios.sort! { |x, y| x['risk'] <=> y['risk']  }
      last_return = 0.0
      portfolios.each_with_index do |portfolio, index|
        if index == 0
          last_return = portfolio['return']
        else
          portfolio['return'] < last_return ? portfolios.delete(portfolio) : (last_return = portfolio['return'])
        end
      end
      portfolios
    end

    def allocations_for(tickers)
      Finance::REfficientFrontier.build(tickers)
    end

  end
end
