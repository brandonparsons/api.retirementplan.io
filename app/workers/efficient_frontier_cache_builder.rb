class EfficientFrontierCacheBuilder
  include Sidekiq::Worker

  sidekiq_options queue: :cache

  ## DISABLED FOR NOW UNTIL TRANSFERRED OVER TO API.....
  # unless ENV['SIDETIQ_ENABLE'] == 'false'
  #   include Sidetiq::Schedulable

  #   unless Rails.env.test? || Rails.env.development? # Too noisy for dev
  #     # recurrence { minutely.second_of_minute(0,15,30,45) } # Every 5 seconds was too much - could not keep up with queued.
  #     recurrence { minutely.second_of_minute(0,30) } # Every 5 seconds was too much - could not keep up with queued.
  #   end
  # end

  def perform
    tickers         = Security.all_tickers
    random_tickers  = tickers.sample(1 + rand(tickers.count))

    puts "[WORKER][EfficientFrontierCacheBuilder]: Queuing up Efficient Frontier build for tickers: #{random_tickers}"

    # EfficientFrontierBuilder normally goes into the default queue (i.e. when
    # users request a portfolio combination).  In this case however, we are just
    # precaching results.  Push to the cache queue so it gets lower priority.
    Sidekiq::Client.push({
      'class' => EfficientFrontierBuilder,
      'queue' => 'cache',
      'args'  => [random_tickers]
    })
  end
end
