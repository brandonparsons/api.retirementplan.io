class PortfolioOutOfBalanceSender
  include SuckerPunch::Job

  def perform(user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.portfolio_out_of_balance(user_id).deliver
    end
  end
end
