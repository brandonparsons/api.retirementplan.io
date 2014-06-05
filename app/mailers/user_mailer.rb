class UserMailer < ActionMailer::Base

  def reset_password_instructions(email, set_password_request: false)
    user    = RegularUser.find_from_all_users_with_email(email)
    subject = set_password_request ? 'Set Password Request' : 'Password Reset Instructions'

    @set_password_request = set_password_request

    if user.present?
      token = CGI.escape(user.password_reset_token)
      @url  = "#{ENV['FRONTEND']}/password_reset/reset/#{token}"
      mail(to: email, subject: subject) do |format|
        format.text
        format.html
      end
    end
  end

  def confirm_email_instructions(email)
    user    = User.find_by email: email
    if user.present?
      token = CGI.escape(user.confirm_email_token)
      @url  = "#{ENV['FRONTEND']}/email_confirmation/confirm/#{token}"
      mail(to: email, subject: 'Email Confirmation Instructions') do |format|
        format.text
        format.html
      end
    end
  end

end
