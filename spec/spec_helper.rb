ENV["RAILS_ENV"] = 'test'

require 'simplecov'
SimpleCov.start 'rails'


require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

##########

require 'zonebie'
Zonebie.set_random_timezone

###########

require 'sidekiq/testing'
Sidekiq::Testing.fake! # As opposed to Sidekiq::Testing.inline!  , which would execute the jobs inline

# -------------------
# expect {
#   HardWorker.perform_async(1, 2)
# }.to change(HardWorker.jobs, :size).by(1)
# -------------------
# assert_equal 0, HardWorker.jobs.size
# HardWorker.perform_async(1, 2)
# assert_equal 1, HardWorker.jobs.size
# -------------------
# HardWorker.jobs.clear ## Clears jobs without performing
# HardWorker.perform_async(1, 2)
# HardWorker.perform_async(2, 3)
# assert_equal 2, HardWorker.jobs.size
# HardWorker.drain  ## Performs all jobs on queue
# assert_equal 0, HardWorker.jobs.size
# -------------------
# assert_equal 0, Sidekiq::Extensions::DelayedMailer.jobs.size
# MyMailer.delay.send_welcome_email('foo@example.com')
# assert_equal 1, Sidekiq::Extensions::DelayedMailer.jobs.size
# -------------------

###########

RSpec.configure do |config|

  config.mock_with :rspec  # :mocha, :flexmock, :rr

  ## Run all tests
  # rspec
  ## Run tests, excluding the ones marked slow
  # rspec --tag ~slow
  ## Always filter out slow (not necessary, set up guardfile to run on start)
  # config.filter_run_excluding slow: true

  # This will make RSpec run all tests that are matched by the given pattern. (And also run the tests in spec/lib)
  # http://stackoverflow.com/questions/9567064/rspec-rails-does-not-run-tests-under-spec-lib
  config.pattern = "**/*_spec.rb"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Allows you to use create(:user) instead of FactoryGirl.create(:user)
  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    DeferredGarbageCollection.start
  end
  config.after(:all) do
    DeferredGarbageCollection.reconsider
  end


  have_redis_connection = false
  begin
    $redis.ping
    have_redis_connection = true
  rescue
    ##
  end
  if have_redis_connection
    # Clear Redis before suite and after each spec
    config.before(:suite) do
      $redis.flushdb
    end
    config.after(:each) do
      $redis.flushdb
    end
  end

end
