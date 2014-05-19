# require 'rserve'

module Finance
  module REfficientFrontier

    extend self

    def build(tickers)
      return ArgumentError unless tickers.is_a?(Array)
      tickers = normalize_tickers(tickers)

      # Only do hard work if we need to (> 2 securities)
      case tickers.length
      when 0
        results = []
      when 1
        results = results_for_single_security(tickers)
      when 2
        results = results_for_two_securities(tickers)
      else
        results = get_efficient_frontier(tickers)
      end

      # There are nil values in there. Remove them. Zeroes are ok.
      return results.map {|allocation| allocation.reject { |k,v| v.nil? } }
    end


    private

    def normalize_tickers(tickers)
      # Always consistently deal with the securities in alphabetical order.
      tickers.map(&:upcase).sort
    end

    def results_for_single_security(tickers)
      [ { tickers[0] => 1.0 } ]
    end

    def results_for_two_securities(tickers)
      [ [0.00, 1.00], [0.05, 0.95], [0.10, 0.90], [0.15, 0.85], [0.20, 0.80], [0.25, 0.75], [0.30, 0.70], [0.35, 0.65], [0.40, 0.60], [0.45, 0.55], [0.50, 0.50], [0.55, 0.45], [0.60, 0.40], [0.65, 0.35], [0.70, 0.30], [0.75, 0.25], [0.80, 0.20], [0.85, 0.15], [0.90, 0.10], [0.95, 0.05], [1.00, 0.00] ].map do |weights_combo|
        {
          tickers[0] => weights_combo[0],
          tickers[1] => weights_combo[1]
        }
      end
    end

    def get_efficient_frontier(tickers)
      frontier  = rserve_request(tickers)
      # Sometimes it can only find a single valid portfolio (the rest must be
      # strictly dominated). In which case it doesn't return as a set of arrays.
      # This breaks array#zip.... Force it into a single-element array.
      frontier = [frontier] unless frontier.first.try(:first)

      frontier.map { |portfolio| Hash[tickers.zip(portfolio)] }
    end

    def rserve_request(tickers)
      raise ArgumentError unless tickers.is_a?(Array)

      con = ::Rserve::Connection.new
      con.assign 'tickers_list', Rserve::REXP::Wrapper.wrap(tickers)
      con.eval <<-EOF
        ## RUN CALCULATION ##
        # Pull a subset from the (preloaded) `all_implied_returns` dataset
        implied_returns = all_implied_returns[tickers_list];

        # Create a dataframe with rows AAA, BBB, CCC. Names of columns are aaa, bbb, ccc
        # There are preloaded sets of return data mapped to tickers, e.g.:
        # BWX <- c(.....)
        return_data         = data.frame( sapply(tickers_list, get) )
        names(return_data)  = sapply(tickers_list, tolower)

        Data = as.timeSeries(return_data);

        # Force means to match implied returns. `forec` function preloaded
        forced_return_data = forec(Data, implied_returns);

        # Build frontiers. `Spec`, `Constraints` preloaded.
        frontier = portfolioFrontier(forced_return_data, Spec, Constraints);
        weights = frontier@portfolio@portfolio[['weights']]
      EOF

      return con.eval('weights').to_ruby.to_a # Returns as matrix
    end

  end
end
