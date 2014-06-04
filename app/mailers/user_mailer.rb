class UserMailer < ActionMailer::Base

  def reset_password_instructions(email)
    user = RegularUser.find_by_email_for_password_reset(email)

    if user.present?
      token = CGI.escape(user.password_reset_token)
      @url  = "#{ENV['FRONTEND']}/password_resets/request/#{token}"
      mail(to: email, subject: 'Password Reset Instructions') do |format|
        format.text
        format.html
      end
    end
  end

end
