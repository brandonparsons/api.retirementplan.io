class Inflation

  #################
  # CLASS METHODS #
  #################

  def self.values
    Rails.cache.fetch("inflation/values", expires_in: 10.minutes) do
      file_location = "#{Rails.root}/db/data/inflation.yml"
      data          = YAML.load(File.read file_location)
      headers       = data.shift # Remove header

      monthly_inflation_values = []
      value_column  = headers.index("weekly_inflation")
      raise "Column not found" if value_column.nil?
      data.each do |row|
        monthly_inflation_values << row[value_column].to_d
      end

      monthly_inflation_values
    end
  end

  def self.mean
    Rails.cache.fetch("inflation/mean", expires_in: 10.minutes) do
      Finance::Statistics.mean(values)
    end
  end

  def self.std_dev
    Rails.cache.fetch("inflation/std_dev", expires_in: 10.minutes) do
      Finance::Statistics.standard_deviation(values)
    end
  end

end
