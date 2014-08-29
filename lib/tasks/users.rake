namespace :users do

  desc "Checks users for out of balance portfolios, and emails if appropriate."
  task check_portfolio_balances: :environment do
    puts "[CheckPortfolioBalances]: Starting CheckPortfolioBalances...."
    User.with_tracked_portfolios.each { |user| user.check_portfolio_balance }
    puts "[CheckPortfolioBalances]: Done...."
  end

end
