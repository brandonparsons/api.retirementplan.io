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

  def ensure_user_completed_questionnaire!
    if current_user && !current_user.has_completed_questionnaire?
      render json: {success: false, message: "You must complete the questionnaire first.", reason: :questionnaire}, status: 403 and return
    end
  end

  def ensure_user_selected_portfolio!
    if current_user && !current_user.has_selected_portfolio?
      render json: {success: false, message: "You must select a portfolio first.", reason: :portfolio}, status: 403 and return
    end
  end

  def ensure_user_selected_expenses!
    if current_user && !current_user.has_selected_expenses?
      render json: {success: false, message: "You must confirm the enabled expenses first.", reason: :expenses}, status: 403 and return
    end
  end

  def ensure_user_has_simulation_input!
    if current_user && !current_user.has_simulation_input?
      render json: {success: false, message: "You must provide simulation inputs first.", reason: :sim_input}, status: 403 and return
    end
  end

  def ensure_user_completed_simulation!
    if current_user && !current_user.has_completed_simulation?
      render json: {success: false, message: "You must complete a retirement simulation first.", reason: :simulation}, status: 403 and return
    end
  end

end
