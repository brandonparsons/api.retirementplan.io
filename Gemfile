source  'https://rubygems.org'
ruby    '2.1.2'

gem 'rails', '4.1.4'
gem 'rails-api'

gem 'active_model_serializers'

gem 'hstore_accessor'
gem 'pg'
gem 'permanent_records'

gem 'redis'
gem 'redis-namespace'

gem 'sidekiq'
gem 'sidetiq', require: false # Manually required so you have ability to turn it off

gem 'hashie'
gem 'faraday'

gem 'markerb'
gem 'redcarpet' # for markerb

gem 'oj'
gem 'oj_mimic_json'
gem 'bcrypt'

gem 'figaro'


group :production do
  gem 'unicorn'
  gem 'kgio' # Speeds up dalli
  gem 'dalli'
  gem 'rack-cache'
  gem 'rails_12factor'
  gem 'rollbar', require: 'rollbar/rails'
end


group :production do
  gem 'newrelic_rpm'
end


group :development, :profile, :test do
  gem 'thin' # Puma doesn't die nicely in development

  gem 'spring'
  gem 'foreman'

  gem 'hirb'
  gem 'awesome_print'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'

  # gem 'rb-fsevent' if RbConfig::CONFIG['target_os'] =~  /darwin/i

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
  gem 'letter_opener'
  gem 'brakeman', require: false
  gem 'sinatra',  require: false # For sidekiq web UI - see sidekiq.rake
end

group :profile do
  gem 'ruby-prof'
end


## Other/Old Gems ##

# gem 'sidekiq-unique-jobs'
# gem 'sidekiq-limit-fetch'
# gem 'roadie'
# gem 'gibberish'
# gem 'bullet'
# gem 'redis-objects'
# gem 'rack-rewrite'
# gem 'attrio'
# gem 'whenever', require: false
# gem 'mandrill-rails' # For mandrill webhooks
# gem 'railroady' # Generates model relation graphs in doc/
