class MinimumRebalanceSpacingSender
  include SuckerPunch::Job

  def perform(user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.min_rebalance_spacing(user_id)
    end
  end
end
