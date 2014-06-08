class Portfolio < ActiveRecord::Base

  hstore_accessor :data,
    selected_etfs:            :hash,
    current_shares:           :hash,
    tracking:                 :boolean


  ################
  # ASSOCIATIONS #
  ################

  belongs_to :user, touch: true


  #############
  # CALLBACKS #
  #############

  before_validation :normalize_weights, :prettify_weights
  before_save       :set_statistics


  ###############
  # VALIDATIONS #
  ###############

  validates :user_id, presence: true
  validate  :weights_must_be_present, :all_weights_match_securities,
    :weights_sum_to_one, :selected_etfs_appropriate


  #################
  # CLASS METHODS #
  #################

  # FIXME: Is this required after going to Ember?
  def self.warnings_for(allocation)
    warning_messages = []

    if large_fraction_small_cap(allocation)
      warning_messages << "This portfolio contains a significant fraction of small cap stocks.  These can be quite volatile - ensure they are acceptable give your risk tolerance."
    end

    if large_fraction_emerging(allocation)
      warning_messages << "This portfolio contains a significant fraction of emerging markets stocks.  These can be quite volatile - ensure they are acceptable give your risk tolerance."
    end

    if not_diversified(allocation)
      warning_messages << "The portfolio you selected has greater than 90% weight in a single asset.  You may select this if you wish, but we suggest that you choose a portfolio with additional diversification."
    end

    return warning_messages
  end


  ####################
  # INSTANCE METHODS #
  ####################

  def tickers
    weights.keys
  end

  def current_allocation
    # Returns the portfolio allocation based on current prices
    current_share_prices  = prices_for_current_shares
    market_value          = current_shares.inject(0) { |sum, (k,v)| sum + (current_share_prices[k] * v.to_f )}

    if market_value == 0.0
      # Returns NaN on divisions - manually force to zero.
      current_shares.inject({}) do |h, (ticker, number_of_shares)|
        h[ticker] = 0.0
        h
      end
    else
      current_shares.inject({}) do |h, (ticker, number_of_shares)|
        h[ticker] = number_of_shares * current_share_prices[ticker].to_f / market_value
        h
      end
    end
  end

  def out_of_balance?(maximum_drift)
    # Determine if the portfolio is out of balance
    # e.g. maximum_drift: 0.05

    target_weights = target_etf_weights

    diffs = current_allocation.inject({}) do |h, (ticker, current_weight)|
      desired_weight  = target_weights[ticker] || 0.0 # If have extraneous securities in current_shares, should be 0.0
      h[ticker]       =  (desired_weight - current_weight).abs
      h
    end
    max_drift = diffs.values.max

    return max_drift > maximum_drift
  end

  def apply_transaction(transaction_hash)
    # NB: It may not be strictly required to convert all these values to floats,
    # however it will be easy to forget that some of these form values are coming
    # back as strings, so just do it.

    transaction_applied = transaction_hash.keys.concat(current_shares.keys).inject({}) do |h , ticker|
      current_value     = (current_shares[ticker] || 0).to_f
      transaction_value = (transaction_hash[ticker] || 0).to_f
      h[ticker] = current_value + transaction_value
      h
    end

    # Remove empty entries
    self.current_shares = transaction_applied.delete_if {|k,v| v.to_f == 0}
  end

  def rebalance(amount_extra=0.0)
    # Returns number of shares of each security to buy, e.g.
    # { "IMO.TO" => 18, "XOM" => -15, "DVN" => 2   }
    # Can specify an additional amount you want to invest along with the rebalance
    # If no additional value specified, defaults to 0 (i.e. simple rebalance)

    final_portfolio_value = current_market_value.to_f + amount_extra.to_f

    if final_portfolio_value == 0
      raise CustomExceptions::NoTrackedPortfolioValue, "You tried to rebalance your portfolio (with no additional funds) when you haven't yet provided us with the number of shares of each security that you hold.  Please complete your tracked portfolio setup."
    end

    tickers_to_check = (current_shares.keys).concat(target_etf_weights.keys).uniq

    shares_to_buy = Finance::Quotes.for_etfs(tickers_to_check).inject({}) do |h, (ticker, price)|
      desired_allocation_of_ticker  = target_etf_weights[ticker].to_f || 0.0
      shares_of_ticker              = current_shares[ticker].to_f || 0.0
      required_end_dollars          = desired_allocation_of_ticker * final_portfolio_value
      dollars_short                 = required_end_dollars - (shares_of_ticker * price)
      shares_needed                 = dollars_short.to_f / price
      h[ticker]                     = shares_needed.round
      h
    end

    return shares_to_buy
  end

  def update_current_shares_with(shares)
    raise "Shares must be a hash" unless shares.is_a?(Hash)

    # Allows an update of existing ETFs, and new ETFs. We want to keep the old
    # ones around so that they can be removed on rebalance.  The new shares
    # win, so they are the argument to the merge.
    self.current_shares = current_shares.merge(shares)
  end


  private

  ## Class-level private ##

  def self.large_fraction_small_cap(allocation)
    allocation.keys.include?("NAESX") && allocation["NAESX"] >= 0.4
  end

  def self.large_fraction_emerging(allocation)
    allocation.keys.include?("EEM") && allocation["EEM"] >= 0.4
  end

  def self.not_diversified(allocation)
    allocation.values.any? {|x| x >= 0.90}
  end


  ## Instance-level private ##

  def normalize_weights
    self.weights = Finance::PortfolioBuilder.normalize_allocation(weights)
  end

  def prettify_weights
    self.prettified_weights = Finance::PortfolioBuilder.prettify_weights(weights)
  end

  def set_statistics
    stats = Finance::PortfolioBuilder.statistics_for_allocation(weights)
    self.expected_return  = stats[:expected_return]
    self.expected_std_dev = stats[:expected_std_dev]
  end

  def target_etf_weights
    # Returns target weights for each ETF - not the overlying security.
    weights.inject({}) do |h, (security_ticker, weight)|
      etf_ticker = selected_etfs[security_ticker]
      h[etf_ticker] = weight
      h
    end
  end

  def current_market_value
    # Returns the current market value of the portfolio
    current_share_prices = prices_for_current_shares
    current_shares.inject(0) { |sum, (k,v)| sum + (current_share_prices[k] * v.to_f )}
  end

  def prices_for_current_shares
    Finance::Quotes.for_etfs(current_shares.keys)
  end

  def weights_must_be_present
    valid_form = weights && weights.is_a?(Hash) && weights.present?
    errors.add(:weights, "must be present and contain a valid hash.") unless valid_form
  end

  def all_weights_match_securities
    weights.keys.each do |ticker|
      security_exists = Security.where(ticker: ticker).any?
      errors.add(:weights, "#{ticker} does not match a valid security.") unless security_exists
    end
  end

  def weights_sum_to_one
    sum = 0
    weights.each_pair do |ticker, weight|
      if weight >= 0.0 && weight <= 1.0001
        sum += weight
      else
        errors.add(:weights, "#{weight} is not a valid weight.")
      end
    end
    errors.add(:weights, "must sum to 1.0 (100%).") unless close_to_one?(sum)
  end

  def close_to_one?(sum)
    sum > 0.995 && sum < 1.005
  end

  def selected_etfs_appropriate
    # If selected ETFs present, check that all selected ETFs are represented in
    # the selected portfolio.
    if selected_etfs.present?
      available_tickers = tickers
      selected_etfs.each do |security_ticker, etf_ticker|
        errors.add(:selected_etfs, "invalid key") unless available_tickers.include?(security_ticker)
      end
    end
  end

end
