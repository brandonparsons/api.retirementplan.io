# No specific test for this class. It is just a helper class for
# ReversePortfolioOptimization, and tested via that class.

module Finance
  module MarketPortfolioComposition

    extend self

    # {
    #   "ticker1" => percentage in mkt port,
    #   "ticker2" => percentage in mkt port
    # }
    # Order alphabetically by ticker, and convert all percentages to numerics.
    # All methods sorting tickers alphabetically to remain consistent.
    def values
      Rails.cache.fetch("marketportcomp/values", expires_in: 10.minutes) do
        sorted_hash
      end
    end


    private

    def sorted_hash
      hsh = {}
      data.keys.sort.each do |k|
        hsh[k] = data[k].to_d
      end

      return hsh
    end

    def data
      raise "File does not exist. You probably need to run rake google_docs." unless File.exists?(market_port_file)
      parsed_yml = YAML.load File.read(market_port_file)
      parsed_yml.shift # pop off headers

      hsh = {}
      parsed_yml.each do |row|
        hsh[row[0]] = row[1]
      end

      return hsh
    end

    def market_port_file
      # Making this a method so you can change the file in tests.
      "#{Rails.root}/db/data/market_portfolio.yml"
    end

  end
end
