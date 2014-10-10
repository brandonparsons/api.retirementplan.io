desc "Send beta end email, note that they have been sent the email"
task :send_beta_end_emails do
  User.all.each do |user|
    unless user.sent_beta_end_email?
      UserMailer.beta_end_email(user.id).deliver
      user.sent_beta_end_email = true
      user.save!
    end
  end
end
