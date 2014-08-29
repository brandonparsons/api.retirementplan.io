class ConfirmEmailInstructionsSender
  include SuckerPunch::Job

  def perform(email, user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.confirm_email_instructions(email: email, user_id: user_id)
    end
  end
end
