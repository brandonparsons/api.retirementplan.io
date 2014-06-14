source  'https://rubygems.org'
ruby    '2.0.0'

gem 'rails', '4.1.1'
gem 'rails-api'


gem 'pg'
gem 'hstore_accessor'
gem 'redis'
gem 'redis-namespace'


gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-limit_fetch'
gem 'sidetiq', require: false # Manually required so you have ability to turn it off


gem 'rserve-client', require: 'rserve'          #, require: false
gem 'statsample'                                #, require: false
gem 'statistics2'                               #, require: false # It kept telling me to install this (probably statsample)
gem 'yahoo-finance', require: 'yahoo_finance'   #, require: false
gem 'recurrence'                                #, require: false # Calculates timelines/schedules


gem 'foreman' # Used to export upstart in production
gem 'figaro'
gem 'oj'
gem 'active_model_serializers'
gem 'bcrypt'
gem 'airbrake' # Only really using in production, but referencing in a class (causes errors if not required)
gem 'markerb'
gem 'redcarpet' # for markerb


group :production, :staging do
  gem 'puma'
  gem 'kgio' # Speeds up dalli
  gem 'dalli'
  gem 'rack-cache'
end


group :production do
  gem 'mandrill-rails'
  gem 'rails_stdout_logging'
  gem 'newrelic_rpm'
end


group :development, :profile, :test do
  gem 'thin' # Puma doesn't die nicely in development

  gem 'spring'

  gem 'faraday'

  gem 'pry-rails'
  gem 'hirb',           require: false
  gem 'awesome_print',  require: false

  gem 'railroady' # Generates model relation graphs in doc/

  gem 'rb-fsevent' if RbConfig::CONFIG['target_os'] =~  /darwin/i

  #########
  # Brought all to dev/test as some are picky about location
  gem 'guard'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rspec-nc'


  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'zonebie'
  gem 'timecop'
  gem 'simplecov', '~> 0.7.1', require: false # Don't upgrade to 0.8 until https://github.com/colszowka/simplecov/issues/281
  #########
end


group :development, :profile do
  gem 'capistrano', '2.15.5',     require: false
  gem 'capistrano-deploy-tagger', require: false

  gem 'google_drive',             require: false # In dev - don't load new data from prod.
  gem 'brakeman',                 require: false

  gem 'letter_opener'

  gem 'sinatra', require: false # For sidekiq web UI - see sidekiq.rake
end

group :profile do
  gem 'ruby-prof'
end


## Other/Old Gems ##

# gem 'roadie'
# gem 'gibberish'
# gem 'bullet'
# gem 'redis-objects'
# gem 'rack-rewrite'
# gem 'attrio'
# gem 'whenever', require: false
