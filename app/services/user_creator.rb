class UserCreator

  def initialize(user_id, user_email, analytics_client_id=nil)
    @user_id              = user_id
    @user_email           = user_email
    @analytics_client_id  = analytics_client_id
  end

  def call
    # Doing these as individual backgrounded steps. Had whole thing as a worker
    # before, but then any failure would cause emails to be delivered multiple
    # times.
    AdminMailer.delay.user_sign_up(@user_id)
    UserMailer.delay.confirm_email_instructions(email: @user_email)
    Expense.delay.create_default_expenses_for(@user_id)
    AnalyticsTracker.delay.track_user_sign_up(user_id: @user_id, analytics_client_id: @analytics_client_id)
  end

end
