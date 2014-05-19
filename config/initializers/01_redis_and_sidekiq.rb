###################
# Configure Redis #
###################

if Rails.env.test?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/4"

elsif Rails.env.development?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/3"

else # production / staging
  raise "MISSING REDIS_SERVER" unless ENV['REDIS_SERVER'].present?
  redis_url     = "redis://#{ENV['REDIS_SERVER']}/0"
end

$redis = Redis.new url: redis_url


#####################
# Configure Sidekiq #
#####################

unless ENV['SIDEKIQ_NAMESPACE']
  puts "Environment variable SIDEKIQ_NAMESPACE was blank - forcing to rp-sidekiq"
  ENV['SIDEKIQ_NAMESPACE'] = 'rp-sidekiq'
end

server_redis_config = {
  namespace:  ENV['SIDEKIQ_NAMESPACE'],
  url:        redis_url
}

client_redis_config = {
  size:       1,
  namespace:  ENV['SIDEKIQ_NAMESPACE'],
  url:        redis_url
}

Sidekiq.configure_server do |config|
  config.redis          = server_redis_config
  # config.poll_interval  = 5 # Running a side job every 5 seconds, remove this if not doing that
end

Sidekiq.configure_client do |config|
  config.redis = client_redis_config
end
