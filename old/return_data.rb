# require 'matrix'

# No specific test for this class. It is just a helper class for
# ReversePortfolioOptimization, and tested via that class.

module Finance
  module ReturnData

    extend self

    # {
    #   "ticker1" => [returns],
    #   "ticker2" => [returns]
    # }
    # Order alphabetically by ticker, and convert all percentages to numerics.
    # All methods sorting tickers alphabetically to remain consistent.
    def values
      Rails.cache.fetch("returndata/values", expires_in: 10.minutes) do
        sorted_hash
      end
    end


    private

    def sorted_hash
      hsh = {}
      data.keys.sort.each do |k|
        hsh[k] = data[k].map(&:to_d)
      end

      return hsh
    end

    def data
      raise "File does not exist. You probably need to run rake google_docs." unless File.exists?(returns_file)
      return_data       = YAML.load(File.read returns_file)
      security_tickers  = return_data.shift
      returns           = Matrix.rows(return_data).transpose # You have returns in vertical columns

      hsh = {}
      security_tickers.each_with_index do |ticker, index|
        hsh[ticker] = returns.row(index)
      end

      return hsh
    end

    def returns_file
      "#{Rails.root}/db/data/returns.yml"
    end

  end
end
