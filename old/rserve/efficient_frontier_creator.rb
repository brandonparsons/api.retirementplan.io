class EfficientFrontierCreator

  def self.warm_cache
    # Build all 1,2 and 3 asset efficient frontiers in cache.
    tickers = Security.all_tickers
    tickers.each { |ticker| new([ticker]).call }
    tickers.combination(2).to_a.each { |combo| new(combo).call } # Doubles
    tickers.combination(3).to_a.each { |combo| new(combo).call } # Triples
  end

  def initialize(tickers_array)
    # So that our cache keys are consistent, and we treat the tickers array like
    # other classes in the program.
    raise "Tickers must be an array" unless tickers_array.is_a?(Array)
    @tickers = tickers_array.map(&:upcase).sort
  end

  def call
    RedisCache.fetch(results_cache_key_for(@tickers), 2.weeks) do
      build_portfolios_for(@tickers)
    end
  end


  private

  def results_cache_key_for(tickers)
    ["portfolios_for", tickers.join('-'), Security.last_updated_time].join("/")
  end

  def build_portfolios_for(tickers)
    portfolios = []
    Finance::REfficientFrontier.build(@tickers).each do |allocation|
      id    = encode_allocation(allocation)
      stats = Finance::PortfolioStatisticsGenerator.statistics_for_allocation(allocation)
      portfolios << {
        id: id,
        allocation: allocation,
        statistics: stats
      }
    end

    cull_portfolios(portfolios)
  end

  def encode_allocation(allocation)
    Base64.urlsafe_encode64(allocation.to_json)
  end

  def cull_portfolios(portfolios)
    # Only include the top-half of the frontier - i.e. portfolios with the
    # highest return for a given level of risk.
    portfolios.sort! { |x, y| x[:statistics][:annual_std_dev] <=> y[:statistics][:annual_std_dev]  }

    last_return = 0.0
    efficient_frontier = []
    portfolios.each_with_index do |portfolio, index|
      if index == 0
        last_return = portfolio[:statistics][:annual_nominal_return]
        efficient_frontier << portfolio
      else
        if portfolio[:statistics][:annual_nominal_return] > last_return
          last_return = portfolio[:statistics][:annual_nominal_return]
          efficient_frontier << portfolio
        end
      end
    end

    return efficient_frontier
  end

end
