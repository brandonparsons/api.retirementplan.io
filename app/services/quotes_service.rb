module QuotesService

  extend self

  ## ONLY CALL quotes_json ONCE! Or cache it in method ##

  def for_etfs(tickers)
    raise "Tickers must be an array" unless tickers.is_a?(Array)
    get_as_objects.select {|k,v| tickers.include?(k) }
  end


  private

  def get_as_objects
    top_level = Hashie::Mash.new(JSON.parse(quotes_json))
    return top_level.quotes
  end

  # def get_as_json
  #   return quotes_json
  # end

  def quotes_json
    conn = Faraday.new(url: ENV['FINANCE_APP'])
    conn.get do |req|
      req.url '/quotes'
      req.headers['Content-Type']   = 'application/json'
      req.headers['Authorization']  = ENV['AUTH_TOKEN']
    end.body
  end

end
