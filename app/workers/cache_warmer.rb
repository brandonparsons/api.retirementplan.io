class CacheWarmer
  include Sidekiq::Worker

  sidekiq_options queue: :cache

  ## DISABLED FOR NOW UNTIL TRANSFERRED OVER TO API.....
  # unless ENV['SIDETIQ_ENABLE'] == 'false'
  #   include Sidetiq::Schedulable
  #   unless Rails.env.test? || Rails.env.development?
  #     recurrence { hourly.minute_of_hour(0, 15, 30, 45) }
  #   end
  # end

  def perform
    puts "[WORKER][CacheWarmer]: Starting CacheWarmer...."
    RetirementSimulation.warm_cache
    Security.warm_cache
    Finance::Quotes.warm_cache
    EfficientFrontierCreator.warm_cache
    puts "[WORKER][CacheWarmer]: Done...."
  end
end
