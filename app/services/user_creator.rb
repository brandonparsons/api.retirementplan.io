class UserCreator

  def initialize(user)
    @user = user
  end

  def call
    AdminMailer.delay.user_sign_up(@user.id)
    UserMailer.delay.confirm_email_instructions(email: @user.email)
    Expense.create_default_expenses_for(@user.id)
  end

end
