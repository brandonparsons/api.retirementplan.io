#######

# NOTE!
# - Can take hours
# - Need to create ports & fronts in Redis Datamapper via script/rserve_dm.rb first
#######


task data_mapper:   ["data_mapper:create_database_records"]

namespace :data_mapper do

  # To create records in DataMapper/redis: `script/rserve_dm.rb`

  desc "Loads up efficient frontiers to database from previously created Redis DataMapper models"
  task create_database_records: :environment do

    previous_level_AR = ActiveRecord::Base.logger.level

    begin
      # Make sure not to generate the long log outputs when updating these
      # attributes.  Slows stuff down
      ActiveRecord::Base.logger.level = Logger::ERROR

      require 'digest'
      require 'data_mapper'
      require 'dm-redis-adapter'
      require 'script/objects/dm_port.rb'
      require 'script/objects/dm_frontier.rb'

      ###################

      DataMapper.setup(:default, {
        adapter: "redis",
        db: 15
      });
      DataMapper::Model.raise_on_save_failure = true
      $redis = Redis.new(db: 15)
      DataMapper.finalize

      ####################

      ##
      # Clear state
      Portfolio.delete_all
      EfficientFrontier.delete_all
      $redis.del "created-dm-portfolios"
      ###


      require 'java'
      @count = java.util.concurrent.atomic.AtomicInteger.new(0)
      approximate_total_ports = 4789900 # For 18 assets

      ####################


      tickers = Security.all.map(&:ticker)

      (1..tickers.length).each do |number_of_assets|

        tickers.combination(number_of_assets).to_a.each do |combo|

          dm_efficient_frontier = DmEfficientFrontier.with_allowable_securities combo
          dm_portfolios         = dm_efficient_frontier.dm_portfolios
          efficient_frontier    = EfficientFrontier.new

          dm_portfolios.each do |dm_portfolio|
            allocation          = dm_portfolio.weights
            portfolio_created   = $redis.sismember("created-dm-portfolios", dm_portfolio.id)

            if portfolio_created
              portfolio   = Portfolio.with_weights(allocation)
            else
              portfolio   = Portfolio.create!(weights: allocation)
              $redis.sadd "created-dm-portfolios", dm_portfolio.id

              current_count = @count.incrementAndGet
              if current_count%100 == 0
                pct_complete = (current_count.to_f / approximate_total_ports) * 100
                puts "Created #{current_count} portfolios. Approximate % complete: #{pct_complete}."
              end

            end

            efficient_frontier.portfolios << portfolio
          end

          efficient_frontier.save!

        end # combo

      end # number_of_assets

    ensure
      ActiveRecord::Base.logger.level = previous_level_AR
    end

    puts "********\nFINISHED\n********"
    puts "If it worked, you probably want to: $redis = Redis.new(db: 15); $redis.flushdb"
  end # task create_database_records_from_datamapper

end # datamapper namespace
