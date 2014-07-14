class TBill

  #################
  # CLASS METHODS #
  #################

  def self.returns
    Rails.cache.fetch("tbill/returns", expires_in: 10.minutes) do
      file_location = "#{Rails.root}/db/data/tbill.yml"
      data          = YAML.load(File.read file_location)
      header        = data.shift # Remove header
      data.flatten.map {|el| el.to_d}
    end
  end

  def self.mean
    Rails.cache.fetch("tbill/mean", expires_in: 10.minutes) do
      Finance::Statistics.mean(values)
    end
  end

  def self.std_dev
    Rails.cache.fetch("tbill/std_dev", expires_in: 10.minutes) do
      Finance::Statistics.standard_deviation(values)
    end
  end

  private

  def self.values
    # Has a different name than other similar classes (RealEstate / Inflation).
    # Convenience method so you can use the same helper methods.
    returns
  end

end
