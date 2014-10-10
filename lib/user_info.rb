class UserInfo

  def initialize(user)
    @user = user
  end

  def created
    "You created your account on #{@user.created_at.strftime("%A %B %d, %Y")}."
  end

  def sign_ins
    "You have signed in #{@user.sign_in_count} times."
  end

  def simulations
    "You have ran #{@user.simulations_ran} simulations."
  end

  def progress
    if @user.has_setup_tracked_portfolio?
      "You completed a retirement simulation, and set up a tracked portfolio."
    elsif @user.has_completed_simulation?
      "You have completed a retirement simulation, but did not set up your portfolio."
    elsif @user.has_selected_portfolio?
      "You have selected a portfolio, but did not complete a retirement simulation."
    elsif @user.has_completed_questionnaire?
      "You have completed the risk tolerance questionnaire, but did not select a portfolio."
    else
      "You haven't completed the risk tolerance questionnaire yet."
    end
  end

end
