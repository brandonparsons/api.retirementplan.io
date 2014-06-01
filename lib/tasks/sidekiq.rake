task :sidekiq do
  require 'sidekiq/web'

  # optional: Process.daemon (and take care of Process.pid to kill process later on)

  Sidekiq.configure_client do |config|
    config.redis = {
      size:       1,
      namespace:  'rp-sidekiq',
      url:        "redis://localhost:6379/3"
    }
  end

  app = Sidekiq::Web
  app.set :environment, :production
  app.set :bind, '0.0.0.0'
  app.set :port, 9494
  app.run!
end
