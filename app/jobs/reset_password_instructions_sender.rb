class ResetPasswordInstructionsSender
  include SuckerPunch::Job

  def perform(email, set_password_request=false)
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.reset_password_instructions(email, set_password_request: set_password_request).deliver
    end
  end
end
