#######

# NOTE!
# - These tasks take hours
# - `efficient_frontiers` task requires that the python critical line algoritm app be running (either on localhost or on internet)
# - Overall `data_mapper` task is called from `rake load_data:efficient_frontiers_and_portfolios`

#######


task data_mapper:   ["data_mapper:efficient_frontiers", "data_mapper:create_database_records"]

namespace :data_mapper do

  desc "Loads up efficient frontiers into datamapper using python app"
  task efficient_frontiers: :environment do
    require 'httparty'
    require 'json'
    require 'data_mapper'
    require 'dm-redis-adapter'
    require 'digest'
    require 'datamapper_models/dm_port.rb'
    require 'datamapper_models/dm_frontier.rb'


    ###################

    ## In-memory adapter ##
    # DataMapper.setup(:default, {adapter: "in_memory"})
    ## Redis Adapter - set the DB so it is separate from other standard uses. ##
    DataMapper.setup(:default, {
      adapter: "redis",
      db: 15
    });
    DataMapper::Model.raise_on_save_failure = true
    $redis = Redis.new(db: 15)
    DataMapper.finalize

    ################

    # CAREFUL! #
    $redis.flushdb

    ###################


    security_implied_returns    = Security.all.inject({}) {|h, security| h[security.ticker] = security.implied_return; h };
    security_historical_returns = Security.all.inject({}) {|h, security| h[security.ticker] = security.returns; h };
    tickers                     = security_implied_returns.keys

    require 'java'
    @count = java.util.concurrent.atomic.AtomicInteger.new(0)
    approximate_total_ports = 2700000 # For 18 assets


    ## Single asset portfolios ##
    puts "\n\n*******************\n ONE-ASSET PORTFOLIOS \n*********************\n\n"

    tickers.each do |ticker|
      e = DmEfficientFrontier.create(allowable_securities: [ticker])

      allocation  = {ticker => 1.0}
      portfolio   = DmPortfolio.with_weights(allocation)
      portfolio   = DmPortfolio.create(weights: allocation) unless portfolio

      @count.incrementAndGet

      e.dm_portfolios << portfolio
      e.save
    end


    ## Two asset portfolio ##
    puts "\n\n*******************\n TWO-ASSET PORTFOLIOS \n*********************\n\n"

    tickers.combination(2).to_a.each do |combo| # combo e.g. - ["GSG", "VDMIX"]
      e = DmEfficientFrontier.create(allowable_securities: combo)

      [ [0.0, 1.0], [0.1, 0.9], [0.2, 0.8], [0.3, 0.7], [0.4, 0.6], [0.5, 0.5], [0.6, 0.4], [0.7, 0.3], [0.8, 0.2], [0.9, 0.1], [1.0, 0.0] ].each do |weights|
        allocation = Hash[combo.zip(weights)]

        portfolio = DmPortfolio.with_weights(allocation)
        portfolio = DmPortfolio.create(weights: allocation ) unless portfolio

        @count.incrementAndGet

        e.dm_portfolios << portfolio
      end

      e.save
    end

    ## Three+ asset portfolios ##
    puts "\n\n*******************\n 3+ ASSET PORTFOLIOS \n*********************\n\n"

    (3..tickers.length).each do |number_of_assets| # You tried threading this, but it blows up. Not worth the effort.
      tickers.combination(number_of_assets).to_a.each do |combo| # combo e.g. - ["GSG", "VDMIX", "VFINX"]
        e = DmEfficientFrontier.create(allowable_securities: combo)

        means   = combo.map {|ticker| security_implied_returns[ticker].to_f}  # Using implied returns, not historical means
        lB      = combo.map {|el| 0.0}
        uB      = combo.map {|el| 1.0}
        covars  = Finance::MatrixMethods.covariance(security_historical_returns.slice(*combo))

        post_data = {
          tickers: combo,
          means: means,
          lB: lB,
          uB: uB,
          covars: covars
        }.to_json

        app_location = ENV['PYTHON_CLA_APP_LOCATION'] || 'http://localhost:5000'
        app_token = ENV['PYTHON_CLA_APP_TOKEN'] || 'abcdef'

        result_json = HTTParty.post("#{app_location}/calc",
          body: post_data,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => app_token
          }
        ).body

        results = JSON.parse(result_json)

        portfolios_to_consider = []

        if results["portfolios"].length > 0
          results["portfolios"].each {|port| portfolios_to_consider << port}
        else
          portfolios_to_consider << results["minimum_variance_portfolio"]
          portfolios_to_consider << results["maximum_sharpe_ratio_portfolio"]
        end

        portfolios_to_consider.each do |cla_portfolio|
          # cla_portfolio e.g. - {
            # "allocations" => {"CSJ"=>0.0, "GSG"=>1.0, "XRE"=>0.0},
            # "mu" => 0.000739728913949089,
            # "sigma" => 0.03675076365155883
          # }

          # Clear out any rediculously small values (e.g. 0.00006E-5)
          allocation    = cla_portfolio["allocations"].inject({}) do |h, (ticker, weight)|
            if weight < 0.0
              h[ticker] = 0.0
            elsif weight > 1.0
              h[ticker] = 1.0
            else
              h[ticker] = weight
            end
            h
          end

          portfolio     = DmPortfolio.with_weights(allocation)

          if portfolio.nil?
            portfolio = DmPortfolio.create( weights: allocation )

            current_count = @count.incrementAndGet
            if current_count%100 == 0
              pct_complete = (current_count.to_f / approximate_total_ports) * 100
              puts "Created #{current_count} portfolios. Approximate % complete: #{pct_complete}."
            end
          end

          e.dm_portfolios  << portfolio

        end # cla_portfolios

        e.save

      end # each combo

    end # number of assets

  end # eff_fronts task


  ########################################


  desc "Loads up efficient frontiers to database using python app"
  task create_database_records: :environment do

    previous_level_AR = ActiveRecord::Base.logger.level

    begin
      # Make sure not to generate the long log outputs when updating these
      # attributes.  Slows stuff down
      ActiveRecord::Base.logger.level = Logger::ERROR

      require 'json'
      require 'digest'
      require 'data_mapper'
      require 'dm-redis-adapter'
      require 'datamapper_models/dm_port.rb'
      require 'datamapper_models/dm_frontier.rb'

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
