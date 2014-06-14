module Finance
  module PortfolioStatisticsGenerator

    extend self

    def statistics_for_allocation(allocation, return_source=:implied_return)
      securities_hash   = summarize_security_data_for(allocation, return_source)
      expected_return   = calculate_expected_return_for(securities_hash)
      expected_std_dev  = calculate_expected_std_dev_for(securities_hash)

      return {
        expected_return:            expected_return,
        expected_std_dev:           expected_std_dev,
        annual_nominal_return_pct:  ( (1 + expected_return) ** 52 - 1 ) * 100 + 2.0,
        annual_std_dev_pct:         expected_std_dev * Math.sqrt(52) * 100
      }
    end


    private

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

  end
end
