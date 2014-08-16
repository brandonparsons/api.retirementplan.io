class UserCreator
  include Sidekiq::Worker

  def perform(user_id, user_email, ga_client_id=nil)
    puts "[WORKER][UserCreator]: Running tasks for #{user_email}."
    AdminMailer.user_sign_up(user_id)
    UserMailer.confirm_email_instructions(email: user_email)
    Expense.create_default_expenses_for(user_id)
    AnalyticsTracker.new(ga_client_id).track_user_sign_up(user_id)
    puts "[WORKER][UserCreator]: Finished."
  end

end
