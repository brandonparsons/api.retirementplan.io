module AssetsService

  extend self

  ## ONLY CALL assets_json ONCE! Or cache it in method ##

  def get_as_json
    return assets_json
  end

  def get_as_objects
    top_level = Hashie::Mash.new(JSON.parse(assets_json))

    # FIXME: Rails will deserializing longer decimal values as BigDecimals, which
    # then get dumped to strings on the way out. Fixing on client side for now,
    # but not consistent.....

    return top_level.assets
  end


  private

  def assets_json
    conn = Faraday.new(url: ENV['FINANCE_APP'])
    conn.get do |req|
      req.url '/assets'
      req.headers['Content-Type']   = 'application/json'
      req.headers['Authorization']  = ENV['AUTH_TOKEN']
    end.body
  end

end
