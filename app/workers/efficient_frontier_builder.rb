class EfficientFrontierBuilder
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
    # Extremely small chance that it might double-queue the same set of tickers.
    # Originally had two classes along with sidekiq-unique-jobs, but adds
    # complexity that is not necessary.  See as far back as commit
    # 22c29516fefc1a45554c8673a35325369195e23a if you want to bring this back.
    tickers         = Security.all_tickers
    random_tickers  = tickers.sample(1 + rand(tickers.count))
    puts "[WORKER][EfficientFrontierBuilder]: Starting EfficientFrontierBuilder with tickers: #{tickers}......"
    EfficientFrontierCreator.new(tickers).call
    puts "[WORKER][EfficientFrontierBuilder]: Done...."
  end
end
