###################
# Configure Redis #
###################


if Rails.env.test?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/2"

elsif Rails.env.development? || Rails.env.profile?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/1"

else # production / staging
  # raise "MISSING REDIS_SERVER" unless ENV['REDIS_SERVER'].present?
  # redis_url     = "redis://#{ENV['REDIS_SERVER']}/0"
  redis_url = ENV['REDISCLOUD_URL']
end

raw_redis = Redis.new url: redis_url
$redis    = Redis::Namespace.new('rp', redis: raw_redis)


#####################
# Configure Sidekiq #
#####################

SIDEKIQ_NAMESPACE = 'rp-sidekiq'

server_redis_config = {
  size:       2,
  namespace:  SIDEKIQ_NAMESPACE,
  url:        redis_url
}

client_redis_config = {
  size:       1,
  namespace:  SIDEKIQ_NAMESPACE,
  url:        redis_url
}

Sidekiq.configure_server do |config|
  config.redis          = server_redis_config
end

Sidekiq.configure_client do |config|
  config.redis = client_redis_config
end
