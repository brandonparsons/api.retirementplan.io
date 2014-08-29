###################
# Configure Redis #
###################

if Rails.env.test?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/2"

elsif Rails.env.development? || Rails.env.profile?
  redis_server  = ENV.fetch('REDIS_SERVER', 'localhost:6379')
  redis_url     = "redis://#{redis_server}/1"

else # production
  # raise "MISSING REDIS_SERVER" unless ENV['REDIS_SERVER'].present?
  # redis_url     = "redis://#{ENV['REDIS_SERVER']}/0"
  redis_url = ENV['REDISCLOUD_URL'] || ENV['REDIS_SERVER']
end

raw_redis = Redis.new url: redis_url
$redis    = Redis::Namespace.new('rp', redis: raw_redis)
