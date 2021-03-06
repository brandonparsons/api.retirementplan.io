task sidekiq: :environment do
  require 'sidekiq/web'

  # optional: Process.daemon (and take care of Process.pid to kill process later on)

  Sidekiq.configure_client do |config|
    config.redis = {
      size:       1,
      namespace:  'rp-sidekiq',
      url:        ENV['REDIS_URL'] || "redis://localhost:6379/1"
    }
  end

  app = Sidekiq::Web
  app.set :environment, :production
  app.set :bind, '0.0.0.0'
  app.set :port, 9494
  app.run!
end
