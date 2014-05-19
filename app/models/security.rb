class Security < ActiveRecord::Base

  ################
  # ASSOCIATIONS #
  ################

  has_many :etfs, dependent: :destroy


  #############
  # CALLBACKS #
  #############

  before_validation :normalize_properties, :set_statistics


  ###############
  # VALIDATIONS #
  ###############

  validates :ticker                 , presence: true, uniqueness: true
  validates :asset_class            , presence: true, inclusion: {
    in: [
      "Canadian Equities",
      "Canadian Long-term Bonds",
      "Canadian Real Estate",
      "Canadian Short-term Bonds",
      "Commodities",
      "International Developed Equities (EAFE)",
      "Emerging Markets Equities",
      "International Real Estate",
      "International Bonds",
      "U.S. Intermediate-term Corporate Bonds",
      "U.S. Intermediate-term Government Bonds",
      "U.S. Long-term Corporate Bonds",
      "U.S. Long-term Government Bonds",
      "U.S. Large-cap Equities",
      "U.S. Real Estate",
      "U.S. Short-term Corporate Bonds",
      "U.S. Short-term Government Bonds",
      "U.S. Small-cap Equities"
    ]
  }
  validates :asset_type       , presence: true, inclusion: { in: [
    "stock",
    "bond",
    "alternative"
  ]}
  validates :mean_return      , presence: true, numericality: {greater_than: -1, less_than: 1}
  validates :std_dev          , presence: true, numericality: {greater_than: -1, less_than: 1}
  validates :implied_return   , presence: true, numericality: {greater_than: -1, less_than: 1}
  validates :returns          , presence: true


  #################
  # CLASS METHODS #
  #################

  def self.warm_cache
    statistics_for_all(:implied_return)
  end

  def self.all_tickers
    cache_key = "securities/all_tickers/#{last_updated_time}"
    Rails.cache.fetch cache_key, expires_in: 1.day do
      Security.all.map(&:ticker)
    end
  end

  def self.asset_class_for_ticker(ticker)
    cache_key = "securities/asset_class_for/#{ticker}/#{last_updated_time}"
    Rails.cache.fetch cache_key, expires_in: 1.day do
      where(ticker: ticker).pluck(:asset_class).first
    end
  end

  def self.available_asset_classes
    cache_key = "securities/available_asset_classes/#{last_updated_time}"
    Rails.cache.fetch cache_key, expires_in: 1.day do
      all_asset_classes = order(:asset_class).select(:id, :ticker, :asset_class).inject({}) do |h, security|
        h[security.asset_class] = security.ticker
        h
      end

      all_asset_classes.delete_if {|asset_class,security_ticker| $DISABLED_SECURITIES.include?(security_ticker) }
    end
  end

  def self.last_updated_time
    # Use this instead of updated_at times for cache keys on securities (better
    # to use a number rather than a date string). Because you load these in as
    # seed data, they won't change very often. This way you don't even have
    # to load individual securities.
    maximum(:updated_at).try(:utc).try(:to_i)
  end

  def self.statistics_for_all(return_source)
    # return_source is `:implied_return` or `:mean_return`
    # Pull all securities stats data from DB. Ordering tickers alphabetically.
    cache_key = "security_stats_data/#{return_source}/#{last_updated_time}"
    Rails.cache.fetch cache_key, compress: true, expires_in: 1.day do
      all.order(:ticker).select([:ticker, return_source, :std_dev, :returns]).map do |security|
        {
          ticker:       security.ticker,
          mean_return:  security.send(return_source),
          std_dev:      security.std_dev,
          returns:      security.returns
        }
      end
    end
  end

  def self.statistics_for(tickers, return_source)
    # return_source is `:implied_return` or `:mean_return`
    raise ArgumentError unless tickers.is_a?(Array)
    return [] if tickers.empty?
    statistics_for_all(return_source).select {|stats| tickers.include?(stats[:ticker])  }
  end


  private

  def normalize_properties
    ticker.upcase!
  end

  def set_statistics
    raise "Invalid returns array" unless (returns.is_a?(Array) && !returns.empty?)
    self.mean_return, self.std_dev = Finance::Statistics.mean_and_standard_deviation(returns)
  end

end
