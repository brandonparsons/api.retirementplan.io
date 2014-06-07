#!/usr/bin/env ruby

require_relative "../config/environment"

require 'rserve'
require 'data_mapper'
require 'dm-redis-adapter'
require 'digest'
require_relative './objects/erp_r_serve'
require_relative './objects/dm_frontier'
require_relative './objects/dm_port'


################
# Instructions #
################

# - Install: Download snapshot from http://rforge.net/Rserve/files/
# - Install: cd ~/Downloads; R CMD INSTALL Rserve_1.8-0.tar.gz
# - R CMD Rserve --no-save
# - (when done - on CL) pkill Rserve


##################
# Script Content #
##################

begin

  puts "*************\nSTARTING SCRIPT\n***************"
  puts Time.now


  ################

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


  ################

  # CAREFUL! #
  $redis.flushdb

  ################


  ################

  r = ErpRServe.new

  ## Load up data ##

  # Reverse Port Optimization implied returns
  implied_returns = {}
  Security.all.each {|security| implied_returns[security.ticker] = security.implied_return.to_f };

  # Historical real adjusted returns (Ri - RFRi + RFRpred)
  historical_excess_returns = Finance::ReversePortfolioOptimization.send(:excess_returns);

  # Risk-free rate
  real_risk_free_rate = Finance::ReversePortfolioOptimization::REAL_WEEKLY_RISKLESS_RATE.to_f

  tickers = implied_returns.keys

  ################


  ################

  require 'java'
  @count = java.util.concurrent.atomic.AtomicInteger.new(0)
  # approximate_total_ports = 2700000 # For 18 assets
  approximate_total_ports = 4789900 # For 18 assets

  beginning_time = Time.now

  ################


  ################

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
  3.upto(tickers.count) do |n|
    tickers.combination(n).to_a.each_with_index do |combo, index|
      e = DmEfficientFrontier.create(allowable_securities: combo)


      implied_to_send     = implied_returns.select {|ticker, returns| combo.include?(ticker)}
      historical_to_send  = historical_excess_returns.select {|ticker, returns| combo.include?(ticker)}

      portfolio_weights   = r.get_efficient_frontiers(real_risk_free_rate, implied_to_send, historical_to_send)

      0.upto(portfolio_weights.length - 1) do |n|
        weights = portfolio_weights[n].values
        allocation_hash = Hash[combo.zip(weights)]

        portfolio = DmPortfolio.with_weights(allocation_hash)

        if portfolio.nil?
          portfolio = DmPortfolio.create( weights: allocation_hash )

          current_count = @count.incrementAndGet
          if current_count%100 == 0
            pct_complete = (current_count.to_f / approximate_total_ports) * 100
            puts "Created #{current_count} portfolios. Approximate % complete: #{pct_complete}."
          end
        end

        e.dm_portfolios  << portfolio

      end

      e.save

    end # combinations
  end # number of securities

  ################


  ################

  end_time = Time.now
  puts "Time elapsed creating efficient frontiers: #{(end_time - beginning_time)} seconds."

  ################

ensure
  puts "\n REMEMBER TO STOP RSERVE."
  puts "`pkill Rserve`"

  puts "*************\nFINISHED SCRIPT\n***************"

end
