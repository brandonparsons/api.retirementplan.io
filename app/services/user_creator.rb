class UserCreator

  def initialize(user, google_analytics_client_id)
    @user         = user
    @ga_client_id = google_analytics_client_id
  end

  def call
    # BE CAREFUL - THIS IS IN USER CREATE CODEPATH - BACKGROUND ALL JOBS!
    AdminMailer.delay.user_sign_up(@user.id)
    UserMailer.delay.confirm_email_instructions(email: @user.email)
    Expense.delay.create_default_expenses_for(@user.id)
    AnalyticsTracker.new(@ga_client_id).delay.track_user_sign_up(@user.id)
  end

end
