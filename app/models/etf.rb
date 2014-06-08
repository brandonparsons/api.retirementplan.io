class Etf < ActiveRecord::Base

  ################
  # ASSOCIATIONS #
  ################

  belongs_to :security, touch: true


  #############
  # CALLBACKS #
  #############

  before_validation :normalize_properties


  ###############
  # VALIDATIONS #
  ###############

  validates :ticker,      presence: true, uniqueness: true
  validates :description, presence: true
  validates :security_id, presence: true


  #################
  # CLASS METHODS #
  #################

  # FIXME: Is this required after going to Ember?
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

  # FIXME: Is this required after going to Ember?
  def self.security_ticker_for_etf(ticker)
    etf = find_by(ticker: ticker)
    return nil unless etf
    etf.security.ticker
  end


  private

  def normalize_properties
    ticker.upcase!
  end

end
