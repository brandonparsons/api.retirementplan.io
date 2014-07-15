class CheckPortfolioBalances
  include Sidekiq::Worker

  unless ENV['SIDETIQ_ENABLE'] == 'false'
    include Sidetiq::Schedulable
    recurrence backfill: true do
      daily.hour_of_day(8)
    end
  end

  def perform
    puts "[WORKER][CheckPortfolioBalances]: Starting CheckPortfolioBalances...."
    User.with_tracked_portfolios.each { |user| user.check_portfolio_balance }
    puts "[WORKER][CheckPortfolioBalances]: Done...."
  end
end
