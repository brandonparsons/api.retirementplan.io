class EtfPurchaseInstructionsSender
  include SuckerPunch::Job

  def perform(id, amount, rebalance_info_hash)
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.etf_purchase_instructions(id, amount, rebalance_info_hash).deliver
    end
  end
end
