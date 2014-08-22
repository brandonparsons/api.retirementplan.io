class AdminUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :simulations_ran, :created_at,
    :confirmed, :accepted_terms, :has_completed_questionnaire,
    :has_selected_portfolio, :has_selected_expenses, :has_simulation_input,
    :has_completed_simulation, :has_selected_etfs, :has_tracked_portfolio

  def confirmed
    object.is_confirmed_or_temporarily_allowed?
  end

  def accepted_terms
    object.has_accepted_terms?
  end

  def has_completed_questionnaire
    object.has_completed_questionnaire?
  end

  def has_selected_portfolio
    object.has_selected_portfolio?
  end

  def has_selected_expenses
    object.has_selected_expenses?
  end

  def has_simulation_input
    object.has_simulation_input?
  end

  def has_completed_simulation
    object.has_completed_simulation?
  end

  def has_selected_etfs
    object.has_selected_etfs?
  end

  def has_tracked_portfolio
    object.has_setup_tracked_portfolio?
  end

end
