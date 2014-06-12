class SecuredController < ApplicationController

  ## ## ##
  ## Careful with the names of these before_actions. Skipping in various controllers ##
  before_action :authenticate_user!
  before_action :verify_user_email_confirmation!
  before_action :confirm_user_accepted_terms!
  ##
  ## ## ##


  protected

  def verify_user_email_confirmation!
    if current_user && !current_user.is_confirmed_or_temporarily_allowed?
      render json: {success: false, message: "You must confirm your email address (#{current_user.email}).", reason: :email_confirmation}, status: 403 and return
    end
  end

  def confirm_user_accepted_terms!
    if current_user && !current_user.has_accepted_terms?
      render json: {success: false, message: "You must accept the Terms & Conditions", reason: :terms}, status: 403 and return
    end
  end

  # def ensure_user_completed_questionnaire!
  #   redirect_to new_questionnaire_path, alert: "You must complete the questionnaire first." unless current_user.has_completed_questionnaire?
  # end

  # def ensure_user_selected_portfolio!
  #   redirect_to select_portfolio_path, alert: "You must select a portfolio first." unless current_user.has_selected_portfolio?
  # end

  # def ensure_user_completed_simulation!
  #   redirect_to simulate_retirement_simulation_path, alert: "You must complete a retirement simulation first." unless current_user.has_completed_simulation?
  # end

end
