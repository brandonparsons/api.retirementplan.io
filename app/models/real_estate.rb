class RealEstate

  #################
  # CLASS METHODS #
  #################

  def self.values
    Rails.cache.fetch("realestate/values", expires_in: 10.minutes) do
      file_location = "#{Rails.root}/db/data/real_estate.yml"
      data          = YAML.load(File.read file_location)
      headers       = data.shift # Remove header

      # Pull price levels from YAML file
      value_column = headers.index("s_p_case_shiller_us_home_price_index")
      raise "Column not found" if value_column.nil?

      price_levels = []
      data.each { |row| price_levels << row[value_column].to_d }

      # The price levels are in absolute terms. Need to re-organize as monthly
      # returns.
      quarterly_returns = []
      price_levels.each_with_index do |val, index|
        next if index == 0
        previous_price_level = price_levels[index - 1]
        quarterly_returns << ( (val - previous_price_level).to_f / previous_price_level ).to_d
      end

      quarterly_returns
    end
  end

  def self.mean
    Rails.cache.fetch("realestate/mean", expires_in: 10.minutes) do
      # Historical Real Estate returns are quarterly. Convert to monthly to match
      # all other securities.
      quarterly_mean = Finance::Statistics.mean(values)
      quarterly_mean_to_monthly(quarterly_mean)
    end
  end

  def self.std_dev
    Rails.cache.fetch("realestate/std_dev", expires_in: 10.minutes) do
      # Historical Real Estate returns are quarterly. Convert to monthly to match
      # all other securities.
      quarterly_std_dev = Finance::Statistics.standard_deviation(values)
      quarterly_std_dev_to_monthly(quarterly_std_dev)
    end
  end


  private

  def self.quarterly_mean_to_monthly(quarterly_mean)
    ( (1 + quarterly_mean) ** (1/3.0) ) - 1
  end

  def self.quarterly_std_dev_to_monthly(quarterly_std_dev)
    quarterly_std_dev.to_f * Math.sqrt(1/3.0)
  end

end
