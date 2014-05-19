source  'https://rubygems.org'
ruby    '2.0.0'

gem 'rails', '4.1.1'
gem 'rails-api'


gem 'pg'
gem 'hstore_accessor'


gem 'foreman' # Used to export upstart in production
gem 'figaro'


gem 'rserve-client', require: 'rserve'          #, require: false
gem 'statsample'                                #, require: false
gem 'statistics2'                               #, require: false # It kept telling me to install this (probably statsample)
gem 'yahoo-finance', require: 'yahoo_finance'   #, require: false
gem 'recurrence'                                #, require: false # Calculates timelines/schedules


gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-limit_fetch'
gem 'sidetiq', require: false # Manually required so you have ability to turn it off


gem 'oj'
gem 'active_model_serializers'
gem 'bcrypt'
gem 'airbrake' # Only really using in production, but referencing in a class (causes errors if not required)
gem 'maildown'


gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-amazon'
gem 'omniauth-linkedin'
# gem 'omniauth-twitter'
# gem 'omniauth-dropbox'


group :production do
  gem 'puma'

  gem 'kgio' # Speeds up dalli
  gem 'dalli'

  gem 'mandrill-rails'
  gem 'rails_stdout_logging'
  gem 'newrelic_rpm'
end


group :development, :test do
  gem 'thin' # Puma doesn't die nicely in development

  gem 'spring'

  gem 'faraday', require: false  # Post to Slack on deploy.

  gem 'pry-rails'
  gem 'hirb',           require: false
  gem 'awesome_print',  require: false

  gem 'railroady' # Generates model relation graphs in doc/

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


group :development do
  gem 'capistrano', '2.15.5',     require: false
  gem 'capistrano-deploy-tagger', require: false

  gem 'google_drive',             require: false # In dev - don't load new data from prod.
  gem 'brakeman',                 require: false

  gem 'letter_opener'
end


def windows_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /mingw|mswin/i ? require_as : false
end
def linux_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /linux/ ? require_as : false
end
# Mac OS X
def darwin_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /darwin/ ? require_as : false
end
gem 'rb-fsevent', group: [:development, :test], require: darwin_only('rb-fsevent') # Faster OSX file change notification


## Will likely need ##

# gem 'launchy'
# gem 'roadie'
# gem 'gibberish'
# gem 'bullet'

## Old gems ##

# gem 'redis-objects'
# gem 'rack-rewrite'
# gem 'attrio'
# gem 'whenever', :require => false # Do actually need whenever on server
