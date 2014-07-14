# require 'set'
# require 'yahoo_finance'

module Finance
  module Quotes

    extend self

    def for_etfs(tickers)
      raise "Tickers must be an array" unless tickers.is_a?(Array)
      if tickers.any?
        all_etfs.select {|k,v| tickers.include?(k) }
      else
        []
      end
    end

    def warm_cache
      send(:all_etfs)
    end

    private

    def all_etfs
      # NB: If you change the name of this method, do above as well in warm_cache

      # Count the number of ETFs so that we can be sure none have been added
      # (which would invalidate the cache).
      cache_key = "#{Etf.count}:YahooQuotes:#{(Time.zone.today).to_s}"

      Rails.cache.fetch(cache_key, expires_in: 2.days) do
        # Grab all of the ETF tickers to build our hash
        tickers     = Etf.pluck(:ticker)
        tickers_set = tickers.to_set

        quotes = YahooFinance.quotes(tickers, [:close], {raw: false}).inject({}) do |h, quote|
          ticker  = quote.symbol
          close   = quote.close
          raise "Invalid symbol"  unless tickers_set.member?(ticker)
          raise "Invalid value"   unless close.is_a?(Float)
          raise "Invalid value"   unless close > 0.0
          h[ticker] = close
          h
        end

        Hash[quotes.sort_by{|k,v| k}]
      end # cache fetch

    end

  end
end
