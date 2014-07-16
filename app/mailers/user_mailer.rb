class UserMailer < ActionMailer::Base

  def etf_purchase_instructions(user_id, rebalance_amount, rebalance_info_hash)
    user            = User.find user_id
    @amount         = rebalance_amount

    # You could probably generate this hash similar to `etf_info_lookup` below
    # in `rebalance_data`, if you do, make sure to check if sending less data
    # from ember would be smart.
    @rebalance_info = rebalance_info_hash

    @new_funds_url = "#{ENV['FRONTEND']}/app/tracked_portfolio/rebalance"
    @dashboard_url = "#{ENV['FRONTEND']}/app/user/dashboard"

    mail(to: user.email, subject: 'ETF Purchasing Instructions') do |format|
      format.text
      format.html
    end
  end


  def portfolio_out_of_balance(user_id)
    user                              = User.find user_id
    @rebalance_info, @etf_info_lookup = rebalance_data(user, 0)

    @new_funds_url = "#{ENV['FRONTEND']}/app/tracked_portfolio/rebalance"
    @dashboard_url = "#{ENV['FRONTEND']}/app/user/dashboard"
    @edit_account_url = "#{ENV['FRONTEND']}/app/user/preferences"

    mail(to: user.email, subject: 'Portfolio out of Balance') do |format|
      format.text
      format.html
    end
  end


  def min_rebalance_spacing(user_id)
    user = User.find user_id

    @tracked_portfolio_url = "#{ENV['FRONTEND']}/app/tracked_portfolio"
    @dashboard_url = "#{ENV['FRONTEND']}/app/user/dashboard"
    @new_funds_url = "#{ENV['FRONTEND']}/app/tracked_portfolio/rebalance"
    @edit_account_url = "#{ENV['FRONTEND']}/app/user/preferences"

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
      @url  = "#{ENV['FRONTEND']}/app/password_reset/reset/#{token}"
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
      @url  = "#{ENV['FRONTEND']}/app/email_confirmation/confirm/#{token}"
      mail(to: email, subject: 'Email Confirmation Instructions') do |format|
        format.text
        format.html
      end
    end
  end


  private

  def rebalance_data(user, rebalance_amount)
    rebalance_info  = user.portfolio.rebalance(rebalance_amount)
    # --> {"EDV"=>-2693, "ICF"=>0, "IFGL"=>0, "IVV"=>1426}
    assets  = AssetsService.get_as_objects
    etfs    = EtfsService.get_as_objects
    etf_info_lookup = rebalance_info.reduce({}) do |memo, (etf_ticker, shares)|
      etf   = etfs.find{|etf| etf.ticker == etf_ticker}
      asset = assets.find{|asset| asset.id == etf.asset_id }
      memo[etf_ticker] = {
        asset_class: asset.asset_class,
        description: etf.description,
      }
      memo
    end
    return rebalance_info, etf_info_lookup
  end

end
