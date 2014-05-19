class Etf < ActiveRecord::Base

  ################
  # ASSOCIATIONS #
  ################

  belongs_to :security


  #############
  # CALLBACKS #
  #############

  before_validation :normalize_properties


  ###############
  # VALIDATIONS #
  ###############

  validates :ticker       , presence: true, uniqueness: true
  validates :description  , presence: true
  validates :security_id  , presence: true


  #################
  # CLASS METHODS #
  #################

  def self.info_lookup_table(tickers=[])
    raise ArgumentError unless tickers.any?

    includes(:security).where(ticker: tickers).references(:securities).inject({}) do |h, etf|
      h[etf.ticker] = {
        asset_class: etf.security.asset_class,
        description: etf.description
      }
      h
    end
  end

  def self.security_ticker_for_etf(ticker)
    etf = find_by(ticker: ticker)
    return nil unless etf
    etf.security.ticker
  end


  ####################
  # INSTANCE METHODS #
  ####################


  private

  def normalize_properties
    ticker.upcase!
  end

end
