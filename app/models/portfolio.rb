# FIXME: Once pulling portfolio data from python, can probably extract this into just a tracked portfolio?

class Portfolio < ActiveRecord::Base

  hstore_accessor :hstore_data,
    weights:                  :hash,
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

  before_validation :normalize_weights


  ###############
  # VALIDATIONS #
  ###############

  validates :user_id, presence: true
  validate  :weights_must_be_present, :all_weights_match_an_asset,
    :weights_sum_to_one, :current_shares_appropriate, :selected_etfs_appropriate


  #################
  # CLASS METHODS #
  #################


  ####################
  # INSTANCE METHODS #
  ####################

  def current_allocation
    # Returns the portfolio allocation based on current prices
    raise "Current shares have not been specified" unless current_shares.present?

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
        h[ticker] = number_of_shares.to_f * current_share_prices[ticker].to_f / market_value
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
    # Returns number of shares of each etf to buy, e.g.
    # { "VDMIX" => 18, "GSG" => -15, "XRE.TO" => 2   }
    # Can specify an additional amount you want to invest along with the rebalance
    # If no additional value specified, defaults to 0 (i.e. simple rebalance)

    final_portfolio_value = current_market_value.to_f + amount_extra.to_f

    # FIXME: Is this required after going to Ember?
    raise CustomExceptions::NoTrackedPortfolioValue if final_portfolio_value == 0

    tickers_to_check = (current_shares.keys).concat(target_etf_weights.keys).uniq

    shares_to_buy = QuotesService.for_etfs(tickers_to_check).inject({}) do |h, (ticker, price)|
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

  def tickers_for_quotes
    tickers_in_current_portfolio           = current_shares.try(:keys)      || []
    tickers_that_are_required_in_portfolio = target_etf_weights.try(:keys)  || []
    relevant_tickers = (tickers_in_current_portfolio + tickers_that_are_required_in_portfolio).uniq
    return relevant_tickers
  end


  private

  ## Instance-level private ##

  def normalize_weights
    normalized_weights = Hash[weights.sort].inject({}) do |h, (k,v)|
      h[k.upcase] = v.to_f
      h
    end
    self.weights = normalized_weights
  end

  def target_etf_weights
    # Returns target weights for each ETF - not the overlying asset.
    return {} unless selected_etfs
    weights.inject({}) do |h, (asset_id, weight)|
      etf_ticker = selected_etfs[asset_id]
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
    QuotesService.for_etfs(current_shares.keys)
  end

  def weights_must_be_present
    valid_form = weights && weights.is_a?(Hash) && weights.present?
    errors.add(:weights, "must be present and contain a valid hash.") unless valid_form
  end

  def all_weights_match_an_asset
    # TODO: Does hitting the AssetsService on every portfolio save cause
    # slowdowns? This is hitting the finance service each time. Could consider
    # caching asset list somehow....
    weights.keys.each do |asset_id|
      asset_exists = AssetsService.get_as_objects.any?{|asset| asset.id == asset_id }
      errors.add(:weights, "#{asset_id} does not match a valid asset.") unless asset_exists
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

  def current_shares_appropriate
    # If current shares not present, don't validate
    return true unless current_shares.present?

    # If so, check valid form
    unless current_shares.is_a?(Hash)
      errors.add(:current_shares, 'must be a hash')
      return false
    end

    # Valid form - convert to floats
    self.current_shares = current_shares.inject({}) do |result, row|
      ticker = row[0]
      shares = row[1]
      result[ticker] = shares.to_f
      result
    end
  end

  def selected_etfs_appropriate
    # If selected ETFs not present, don't validate
    return true unless selected_etfs.present?

    # If so, check valid form
    unless selected_etfs.is_a?(Hash)
      errors.add(:selected_etfs, 'must be a hash')
      return false
    end

    ## REMOVED
    ## Need to be able to save portfolio changes, and then have the user go over
    ## to the etf select page. Will enforce that transition on the client side.
    ## Means that selected_etfs can be temporarily out of sync on the server...
    ## Consider checking in a worker (and email the user), or just assume missing
    ## keys have zero shares.
    # # Valid form - check that all selected ETFs are represented in the
    # # selected portfolio.
    # selected_etfs.each do |asset_id, etf_ticker|
    #   errors.add(:selected_etfs, "invalid key") unless weights.keys.include?(asset_id)
    # end
  end

end
