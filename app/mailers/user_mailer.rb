class UserMailer < ActionMailer::Base

  def etf_purchase_instructions(user_id, rebalance_amount, rebalance_info_hash)
    user            = User.find user_id
    @rebalance_info = rebalance_info_hash
    @amount         = rebalance_amount

    @new_funds_url = "#{ENV['FRONTEND']}/tracked_portfolio/rebalance"
    @dashboard_url = "#{ENV['FRONTEND']}/user/dashboard"

    mail(to: user.email, subject: 'ETF Purchasing Instructions') do |format|
      format.text
      format.html
    end
  end


  def portfolio_out_of_balance(user_id)
    user                              = User.find user_id
    @rebalance_info, @etf_info_lookup = rebalance_data(user, 0)

    @new_funds_url = ""
    @dashboard_url = ""
    @edit_account_url = ""

    mail(to: user.email, subject: 'Portfolio out of Balance') do |format|
      format.text
      format.html
    end
  end


  def min_rebalance_spacing(user_id)
    user = User.find user_id

    @tracked_portfolio_url = ""
    @dashboard_url = ""
    @new_funds_url = ""
    @edit_account_url = ""

    mail(to: user.email, subject: 'Portfolio Check-in') do |format|
      format.text
      format.html
    end
  end


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


  def confirm_email_instructions(email: nil, user_id: nil)
    raise "Email required." unless email.present?

    if user_id.present?
      user = User.find user_id
    else
      user = User.find_by email: email
    end

    if user.present?
      token = CGI.escape(user.confirm_email_token for_email: email)
      @url  = "#{ENV['FRONTEND']}/email_confirmation/confirm/#{token}"
      mail(to: email, subject: 'Email Confirmation Instructions') do |format|
        format.text
        format.html
      end
    end
  end


  private

  def rebalance_data(user, rebalance_amount)
    rebalance_info  = user.portfolio.rebalance(rebalance_amount)
    etf_info_lookup = Etf.info_lookup_table(rebalance_info.keys.concat(user.portfolio.current_shares.keys).uniq)
    return rebalance_info, etf_info_lookup
  end

end
