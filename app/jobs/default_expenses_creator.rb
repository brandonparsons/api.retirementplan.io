class DefaultExpensesCreator
  include SuckerPunch::Job

  def perform(user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Expense.create_default_expenses_for(user_id)
    end
  end
end
