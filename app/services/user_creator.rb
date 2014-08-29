class UserCreator

  def initialize(user_id, user_email)
    @user_id    = user_id
    @user_email = user_email
  end

  def call
    # Doing these as individual backgrounded steps. Had whole thing as a worker
    # before, but then any failure would cause emails to be delivered multiple
    # times.
    AdminNotifier.new.async.perform("new_user", @user_id)
    ConfirmEmailInstructionsSender.new.async.perform(@user_email, nil)
    DefaultExpensesCreator.new.async.perform(@user_id)
  end

end
