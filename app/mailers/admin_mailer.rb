class AdminMailer < ActionMailer::Base

  def user_sign_up(user_id)
    @user = User.find user_id
    mail(to: ENV['ADMIN_MAIL_RECEIVER'], subject: 'New user signup!')
  end

end
