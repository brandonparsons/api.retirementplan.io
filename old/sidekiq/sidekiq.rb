#####################
# Configure Sidekiq #
#####################

SIDEKIQ_NAMESPACE = 'rp-sidekiq' # If you change this, need to change in www app too (if still using that for web monitor)

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
