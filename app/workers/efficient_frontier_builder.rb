class EfficientFrontierBuilder
  include Sidekiq::Worker

  sidekiq_options unique: true

  def perform(tickers)
    puts "[WORKER][EfficientFrontierBuilder]: Starting EfficientFrontierBuilder with tickers: #{tickers}......"
    Finance::PortfolioBuilder.build_portfolios_for(tickers)
    puts "[WORKER][EfficientFrontierBuilder]: Done...."
  end
end
