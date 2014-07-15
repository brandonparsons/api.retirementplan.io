require 'base64'

class EfficientFrontierCreator

  def initialize(asset_ids)
    raise "Asset ID's must be an array" unless asset_ids.is_a?(Array)

    # Upcase/sort so that cache keys (if using) are always consistent.
    @asset_ids = asset_ids.map(&:upcase).sort
  end

  def call
    # This is where you'd do a cache call (with expiry < expected python data
    # updates) if you want to cache this values inside the rails-API boundaries
    build_portfolios_for(@asset_ids)
  end


  private

  def build_portfolios_for(asset_ids)
    response = get_data_from_remote(asset_ids)

    # Rails is deserializing longer decimal values as BigDecimals, which
    # then get dumped to strings on the way out. Need to fix this every time.
    # FIXME: Is there a better way?
    return sanitize_portfolios_and_add_ids(response.portfolios)
  end

  def get_data_from_remote(asset_ids)
    conn = Faraday.new(url: ENV['FINANCE_APP'])
    payload = { asset_ids: asset_ids }

    response = Hashie::Mash.new(JSON.parse(conn.get do |req|
      req.url '/efficient_frontier'
      req.headers['Content-Type']   = 'application/json'
      req.headers['Authorization']  = ENV['AUTH_TOKEN']
      req.body                      = payload.to_json
    end.body))

    return response
  end

  def encode_allocation(allocation)
    Base64.urlsafe_encode64(allocation.to_json)
  end

  def sanitize_portfolios_and_add_ids(portfolios)
    return portfolios.reduce([]) do |memo, portfolio|
      memo << sanitize_portfolio(portfolio)
      memo
    end
  end

  def sanitize_portfolio(portfolio)
    sanitized_allocation = FloatMapper.call(portfolio.allocation)
    sanitized_statistics = FloatMapper.call(portfolio.statistics)

    return {
      "id"          => encode_allocation(sanitized_allocation),
      "allocation"  => sanitized_allocation,
      "statistics"  => sanitized_statistics,
    }
  end

end
