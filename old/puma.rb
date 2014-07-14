######################
# PUMA CONFIGURATION #
######################

rails_env = ENV['RAILS_ENV'] || 'development'
dev_environment = (rails_env == 'development')


## Allow workers to reload bundler context when master process is issued
## a USR1 signal. This allows proper reloading of gems while the master
## is preserved across a phased-restart. (incompatible with preload_app)
## (off by default)
# Doesn't seem to be working..... see if ENV['BUNDLE_GEMFILE'] below works...
# prune_bundler


# The directory to operate out of.
#
# The default is the current directory.
#
directory '/opt/apps/retirementplan.io/current' unless dev_environment


# Load “path” as a rackup file.
#
# The default is “config.ru”.
#
rackup '/opt/apps/retirementplan.io/current/config.ru' unless dev_environment


on_worker_boot do
  require "active_record"

  gemfile           = File.expand_path('../../Gemfile',  __FILE__)
  database_yml_file = File.expand_path('../../config/database.yml',  __FILE__)

  # https://github.com/puma/puma/issues/300
  ENV["BUNDLE_GEMFILE"] = gemfile


  ####
  # Suggested by Heroku for Puma web server:
  # https://devcenter.heroku.com/articles/concurrency-and-database-connections

  ActiveRecord::Base.connection_pool.disconnect! rescue ActiveRecord::ConnectionNotEstablished

  ActiveSupport.on_load(:active_record) do
    config = YAML.load_file(database_yml_file)[rails_env]
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
    config['pool']              = ENV['DB_POOL']      || ENV['MAX_THREADS'] || 10
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"] || config)
  end
  ####

end


# Configure “min” to be the minimum number of threads to use to answer
# requests and “max” the maximum.
#
# The default is “0, 16”.
#
if dev_environment
  threads 1, 1
else
  min_threads = ENV['MIN_THREADS'] || 1
  max_threads = ENV['MAX_THREADS'] || 6
  threads min_threads, max_threads
end


# How many worker processes to run.
#
# The default is “0”.
#
if dev_environment
  workers 2
else
  workers 3
end


# Bind the server to “url”. “tcp://”, “unix://” and “ssl://” are the only
# accepted protocols.
#
# The default is “tcp://0.0.0.0:9292”.
#
# bind 'tcp://0.0.0.0:9292'
# bind 'unix:///var/run/puma.sock'
# bind 'unix:///var/run/puma.sock?umask=0777'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'

if dev_environment
  bind "tcp://127.0.0.1:#{ENV['PORT'] || 3000}"
else
  bind 'unix:///tmp/app.sock'
end


# Reading this file directly in puma_phased_restart
pidfile '/tmp/puma.pid'
